import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import cron from 'node-cron';
import pg from 'pg';
import { randomInt } from 'crypto';
import { OAuth2Client } from 'google-auth-library';
import twilio from 'twilio';

const { Pool } = pg;
const googleClient = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID || undefined);
const twilioClient = process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN ? twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN) : null;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(',') ?? '*', credentials: true }));
app.use(express.json({ limit: '1mb' }));

function tokenFor(user) { return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' }); }
async function auth(req, res, next) {
  try {
    const raw = req.headers.authorization?.replace('Bearer ', '');
    if (!raw) return res.status(401).json({ message: 'Authentication required' });
    const payload = jwt.verify(raw, process.env.JWT_SECRET);
    const { rows } = await pool.query('SELECT * FROM users WHERE id=$1', [payload.sub]);
    if (!rows[0]) return res.status(401).json({ message: 'Session expired' });
    req.user = rows[0]; next();
  } catch { res.status(401).json({ message: 'Invalid or expired token' }); }
}
function roles(...allowed) { return (req, res, next) => allowed.includes(req.user.role) ? next() : res.status(403).json({ message: 'Forbidden' }); }

app.get('/health', (_, res) => res.json({ ok: true }));
app.get('/api/services', async (_, res) => { const { rows } = await pool.query('SELECT id,name,description,image_url FROM services WHERE enabled=true ORDER BY name'); res.json({ items: rows }); });
app.get('/api/services/:id/locations', async (req, res) => { const { rows } = await pool.query(`SELECT l.id,l.name,l.city,l.governorate FROM locations l JOIN service_locations sl ON sl.location_id=l.id WHERE sl.service_id=$1 AND l.enabled=true ORDER BY l.name`, [req.params.id]); res.json({ items: rows }); });
app.get('/api/slots', async (req, res) => {
  const { service_id, location_id, date } = req.query;
  if (!service_id || !location_id || !date) return res.status(400).json({ message: 'service_id, location_id and date are required' });
  const { rows } = await pool.query(`SELECT s.id,to_char(s.starts_at AT TIME ZONE 'UTC','HH24:MI') starts_at,to_char(s.ends_at AT TIME ZONE 'UTC','HH24:MI') ends_at,NOT EXISTS (SELECT 1 FROM bookings b WHERE b.slot_id=s.id AND b.status IN ('pending','confirmed')) available FROM slots s WHERE s.service_id=$1 AND s.location_id=$2 AND s.enabled=true AND s.starts_at::date=$3 ORDER BY s.starts_at`, [service_id, location_id, date]);
  res.json({ items: rows });
});

app.post('/api/auth/phone/request', async (req, res) => {
  const phone = String(req.body.phone || '').trim();
  if (phone.length < 8) return res.status(400).json({ message: 'Invalid phone number' });
  const code = String(randomInt(100000, 1000000));
  const hash = await bcrypt.hash(code, 10);
  await pool.query(`INSERT INTO otp_codes(phone,code_hash,expires_at) VALUES($1,$2,now()+make_interval(mins=>$3))`, [phone, hash, Number(process.env.OTP_TTL_MINUTES || 5)]);
  if (twilioClient && process.env.TWILIO_FROM_NUMBER) { await twilioClient.messages.create({ body: `Your Service Booking verification code is ${code}`, from: process.env.TWILIO_FROM_NUMBER, to: phone }); }
  res.json(process.env.OTP_DEV_MODE === 'true' ? { ok: true, dev_code: code } : { ok: true });
});

app.post('/api/auth/phone/verify', async (req, res) => {
  const phone = String(req.body.phone || '').trim(); const code = String(req.body.code || '').trim();
  const { rows } = await pool.query('SELECT * FROM otp_codes WHERE phone=$1 AND used_at IS NULL AND expires_at>now() ORDER BY created_at DESC LIMIT 1', [phone]);
  const otp = rows[0]; if (!otp || otp.attempts >= 5 || !(await bcrypt.compare(code, otp.code_hash))) return res.status(401).json({ message: 'Invalid or expired OTP' });
  await pool.query('UPDATE otp_codes SET used_at=now() WHERE id=$1', [otp.id]);
  let user = (await pool.query('SELECT * FROM users WHERE phone=$1', [phone])).rows[0];
  if (!user) user = (await pool.query('INSERT INTO users(phone,full_name) VALUES($1,$2) RETURNING *', [phone, 'New customer'])).rows[0];
  res.json({ access_token: tokenFor(user), user });
});

app.post('/api/auth/google', async (req, res) => {
  try {
    const idToken = String(req.body.id_token || '');
    if (!idToken) return res.status(400).json({ message: 'id_token is required' });
    const ticket = await googleClient.verifyIdToken({ idToken, audience: process.env.GOOGLE_WEB_CLIENT_ID || undefined });
    const p = ticket.getPayload();
    if (!p?.sub || !p.email) return res.status(401).json({ message: 'Invalid Google identity' });
    let user = (await pool.query('SELECT * FROM users WHERE email=$1', [p.email])).rows[0];
    if (!user) user = (await pool.query('INSERT INTO users(email,full_name) VALUES($1,$2) RETURNING *', [p.email, p.name || 'Customer'])).rows[0];
    res.json({ access_token: tokenFor(user), user });
  } catch { res.status(401).json({ message: 'Google authentication failed' }); }
});

app.get('/api/me', auth, (req, res) => res.json({ user: req.user }));

app.post('/api/bookings', auth, async (req, res) => {
  if (req.user.role !== 'customer') return res.status(403).json({ message: 'Only customers can create bookings' });
  const { service_id, location_id, slot_id } = req.body;
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const slot = (await client.query(`SELECT s.*, l.enabled location_enabled, sv.enabled service_enabled FROM slots s JOIN locations l ON l.id=s.location_id JOIN services sv ON sv.id=s.service_id WHERE s.id=$1 FOR UPDATE`, [slot_id])).rows[0];
    if (!slot || slot.service_id !== service_id || slot.location_id !== location_id || !slot.enabled || !slot.location_enabled || !slot.service_enabled) throw Object.assign(new Error('Slot unavailable'), { status: 409 });
    const assigned = (await client.query(`SELECT pa.provider_id,pa.booking_mode FROM provider_assignments pa WHERE pa.location_id=$1 AND pa.service_id=$2 ORDER BY pa.id LIMIT 1`, [location_id, service_id])).rows[0];
    if (!assigned) throw Object.assign(new Error('No provider assigned'), { status: 409 });
    const status = assigned.booking_mode === 'instant' ? 'confirmed' : 'pending';
    const expires = status === 'pending' ? new Date(Date.now() + 4 * 60 * 60 * 1000) : null;
    const booking = (await client.query(`INSERT INTO bookings(customer_id,service_id,location_id,slot_id,provider_id,status,booking_mode,confirmed_at,expires_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING *`, [req.user.id, service_id, location_id, slot_id, assigned.provider_id, status, assigned.booking_mode, status === 'confirmed' ? new Date() : null, expires])).rows[0];
    await client.query('INSERT INTO notifications(user_id,type,title,body) VALUES($1,$2,$3,$4)', [req.user.id, 'booking_created', 'Booking created', status === 'confirmed' ? 'Your booking is confirmed.' : 'Your booking is pending provider confirmation.']);
    await client.query('COMMIT'); res.status(201).json({ booking });
  } catch (e) { await client.query('ROLLBACK'); res.status(e.status || (e.code === '23505' ? 409 : 500)).json({ message: e.message || 'Booking failed' }); }
  finally { client.release(); }
});

app.get('/api/bookings/me', auth, async (req, res) => { const { rows } = await pool.query(`SELECT b.id,sv.name service_name,l.name location_name,b.status,to_char(s.starts_at AT TIME ZONE 'UTC','YYYY-MM-DD') date,to_char(s.starts_at AT TIME ZONE 'UTC','HH24:MI') time FROM bookings b JOIN services sv ON sv.id=b.service_id JOIN locations l ON l.id=b.location_id JOIN slots s ON s.id=b.slot_id WHERE b.customer_id=$1 ORDER BY s.starts_at DESC`, [req.user.id]); res.json({ items: rows }); });

app.post('/api/bookings/:id/cancel', auth, async (req, res) => {
  const client = await pool.connect(); try { await client.query('BEGIN'); const b = (await client.query(`SELECT b.*,s.starts_at FROM bookings b JOIN slots s ON s.id=b.slot_id WHERE b.id=$1 FOR UPDATE`, [req.params.id])).rows[0]; if (!b || b.customer_id !== req.user.id) throw Object.assign(new Error('Booking not found'), {status:404}); if (!['pending','confirmed'].includes(b.status)) throw Object.assign(new Error('Booking cannot be cancelled'), {status:409}); if (new Date(b.starts_at).getTime() - Date.now() <= 3*60*60*1000) throw Object.assign(new Error('Cancellation is blocked within 3 hours of the appointment'), {status:409}); await client.query(`UPDATE bookings SET status='cancelled',cancelled_at=now(),updated_at=now() WHERE id=$1`, [b.id]); await client.query('COMMIT'); res.json({ok:true}); } catch(e) { await client.query('ROLLBACK'); res.status(e.status||500).json({message:e.message||'Cancel failed'}); } finally {client.release();} });

app.get('/api/provider/bookings', auth, roles('provider','admin'), async (req,res) => { const sql = req.user.role==='admin' ? `SELECT b.*,s.starts_at,sv.name service_name,l.name location_name FROM bookings b JOIN slots s ON s.id=b.slot_id JOIN services sv ON sv.id=b.service_id JOIN locations l ON l.id=b.location_id ORDER BY s.starts_at DESC LIMIT 200` : `SELECT b.*,s.starts_at,sv.name service_name,l.name location_name FROM bookings b JOIN slots s ON s.id=b.slot_id JOIN services sv ON sv.id=b.service_id JOIN locations l ON l.id=b.location_id JOIN provider_assignments pa ON pa.provider_id=$1 AND pa.location_id=b.location_id AND pa.service_id=b.service_id ORDER BY s.starts_at DESC LIMIT 200`; const {rows}=await pool.query(sql, req.user.role==='admin'?[]:[req.user.id]); res.json({items:rows}); });
app.post('/api/provider/bookings/:id/confirm', auth, roles('provider','admin'), async (req,res)=>{ const q=await pool.query(`UPDATE bookings SET status='confirmed',confirmed_at=now(),updated_at=now() WHERE id=$1 AND status='pending' RETURNING *`,[req.params.id]); if(!q.rows[0]) return res.status(409).json({message:'Booking is no longer pending'}); res.json({booking:q.rows[0]}); });
app.post('/api/provider/bookings/:id/cancel', auth, roles('provider','admin'), async (req,res)=>{ const client=await pool.connect(); try{await client.query('BEGIN'); const b=(await client.query(`SELECT * FROM bookings WHERE id=$1 FOR UPDATE`,[req.params.id])).rows[0]; if(!b) throw Object.assign(new Error('Not found'),{status:404}); if(req.user.role==='provider'){const a=(await client.query(`SELECT 1 FROM provider_assignments WHERE provider_id=$1 AND location_id=$2 AND service_id=$3`,[req.user.id,b.location_id,b.service_id])).rows[0]; if(!a) throw Object.assign(new Error('Forbidden'),{status:403});} await client.query(`UPDATE bookings SET status='cancelled',cancelled_at=now(),updated_at=now() WHERE id=$1`,[b.id]); await client.query(`INSERT INTO audit_logs(actor_id,action,booking_id,metadata) VALUES($1,'provider_cancelled_booking',$2,$3)`,[req.user.id,b.id,JSON.stringify({responsibility_warning:true})]); await client.query('COMMIT'); res.json({ok:true});}catch(e){await client.query('ROLLBACK');res.status(e.status||500).json({message:e.message||'Cancel failed'});}finally{client.release();}});

app.post('/api/admin/services', auth, roles('admin'), async(req,res)=>{const {name,description='',image_url=''}=req.body; const {rows}=await pool.query(`INSERT INTO services(name,description,image_url) VALUES($1,$2,$3) RETURNING *`,[name,description,image_url]);res.status(201).json({service:rows[0]});});
app.put('/api/admin/services/:id', auth, roles('admin'), async(req,res)=>{const {name,description,image_url,enabled}=req.body;const {rows}=await pool.query(`UPDATE services SET name=COALESCE($1,name),description=COALESCE($2,description),image_url=COALESCE($3,image_url),enabled=COALESCE($4,enabled),updated_at=now() WHERE id=$5 RETURNING *`,[name,description,image_url,enabled,req.params.id]);res.json({service:rows[0]});});
app.post('/api/admin/locations', auth, roles('admin'), async(req,res)=>{const {name,governorate,city}=req.body;const {rows}=await pool.query(`INSERT INTO locations(name,governorate,city) VALUES($1,$2,$3) RETURNING *`,[name,governorate,city]);res.status(201).json({location:rows[0]});});
app.post('/api/admin/assignments', auth, roles('admin'), async(req,res)=>{const {provider_id,location_id,service_id,booking_mode}=req.body;const {rows}=await pool.query(`INSERT INTO provider_assignments(provider_id,location_id,service_id,booking_mode) VALUES($1,$2,$3,$4) RETURNING *`,[provider_id,location_id,service_id,booking_mode]);res.status(201).json({assignment:rows[0]});});

cron.schedule('* * * * *', async () => { try { await pool.query(`UPDATE bookings SET status='expired',updated_at=now() WHERE status='pending' AND expires_at<=now()`); } catch (e) { console.error('expiration worker', e.message); } });

const port = Number(process.env.PORT || 8080); app.listen(port, () => console.log(`Service Booking API listening on ${port}`));
