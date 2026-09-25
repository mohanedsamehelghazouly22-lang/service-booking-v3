import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../repositories/app_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api, required this.repository});
  final ApiClient api;
  final AppRepository repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  bool otpSent = false;
  bool loading = false;
  String? error;

  Future<void> _sendOtp() async {
    if (phone.text.trim().length < 8) {
      setState(() => error = 'Enter a valid phone number.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      await widget.repository.sendOtp(phone.text.trim());
      if (mounted) setState(() => otpSent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _google() async {
    setState(() { loading = true; error = null; });
    try {
      await widget.repository.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verify() async {
    setState(() { loading = true; error = null; });
    try {
      await widget.repository.verifyOtp(phone.text.trim(), otp.text.trim());
      if (!mounted) return;
      await widget.repository.profile();
      _openRole();
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openRole() async {
    try {
      final profile = await widget.repository.profile();
      final role = profile['role']?.toString();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        role == 'admin' ? '/admin' : role == 'provider' ? '/provider' : '/home',
      );
    } catch (_) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(17)),
                child: const Icon(Icons.bolt_rounded, color: AppColors.orange, size: 30),
              ),
              const SizedBox(height: 44),
              const Text('Welcome back', style: TextStyle(color: AppColors.ink, fontSize: 38, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('Book trusted services around you in a few taps.', style: TextStyle(color: AppColors.ink, fontSize: 16)),
              const SizedBox(height: 36),
              if (!otpSent) ...[
                const Text('Phone number', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_outlined), hintText: '+20 10 1234 5678'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _sendOtp,
                    child: loading ? const CircularProgressIndicator() : const Text('Continue with phone'),
                  ),
                ),
              ] else ...[
                Text('Code sent to ${phone.text}', style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(controller: otp, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(hintText: '••••••')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : _verify,
                    child: loading ? const CircularProgressIndicator() : const Text('Verify & continue'),
                  ),
                ),
                TextButton(onPressed: loading ? null : () => setState(() => otpSent = false), child: const Text('Change phone')),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.black26)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700))),
                  Expanded(child: Divider(color: Colors.black26)),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : _google,
                  icon: const Icon(Icons.g_mobiledata, color: AppColors.ink),
                  label: const Text('Continue with Google', style: TextStyle(color: AppColors.ink)),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text('Browse as guest', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
