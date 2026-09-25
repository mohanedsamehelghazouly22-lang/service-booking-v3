create or replace function public.create_booking(
  p_customer_id uuid,
  p_service_id uuid,
  p_location_id uuid,
  p_slot_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_mode varchar(16);
  v_provider uuid;
  v_booking public.bookings;
begin
  if auth.uid() is null or auth.uid() <> p_customer_id then
    raise exception 'unauthorized';
  end if;

  select pa.booking_mode, pa.provider_id
    into v_mode, v_provider
  from public.provider_assignments pa
  where pa.service_id = p_service_id
    and pa.location_id = p_location_id
  order by pa.id
  limit 1;

  if v_mode is null then
    raise exception 'service_location_not_available';
  end if;

  if not exists (
    select 1 from public.slots s
    where s.id = p_slot_id
      and s.service_id = p_service_id
      and s.location_id = p_location_id
      and s.enabled = true
      and s.starts_at > now()
  ) then
    raise exception 'slot_not_available';
  end if;

  insert into public.bookings (
    customer_id, service_id, location_id, slot_id, provider_id,
    status, booking_mode, confirmed_at, expires_at
  )
  values (
    p_customer_id, p_service_id, p_location_id, p_slot_id, v_provider,
    case when v_mode = 'instant' then 'confirmed' else 'pending' end,
    v_mode,
    case when v_mode = 'instant' then now() else null end,
    case when v_mode = 'pending' then now() + interval '4 hours' else null end
  )
  returning * into v_booking;

  return jsonb_build_object(
    'booking', to_jsonb(v_booking),
    'status', v_booking.status
  );
exception
  when unique_violation then
    raise exception 'slot_already_booked';
end;
$$;

revoke all on function public.create_booking(uuid,uuid,uuid,uuid) from public;
grant execute on function public.create_booking(uuid,uuid,uuid,uuid) to authenticated;

create or replace function public.cancel_booking(p_booking_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings;
begin
  if auth.uid() is null then raise exception 'unauthorized'; end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
    and customer_id = auth.uid()
  for update;

  if not found then raise exception 'booking_not_found'; end if;
  if v_booking.status not in ('pending','confirmed') then raise exception 'booking_not_cancellable'; end if;

  if exists (select 1 from public.slots s where s.id = v_booking.slot_id and s.starts_at <= now() + interval '3 hours') then
    raise exception 'cancellation_window_closed';
  end if;

  update public.bookings
  set status = 'cancelled', cancelled_at = now(), updated_at = now()
  where id = p_booking_id
  returning * into v_booking;

  return jsonb_build_object('booking', to_jsonb(v_booking), 'status', v_booking.status);
end;
$$;

revoke all on function public.cancel_booking(uuid) from public;
grant execute on function public.cancel_booking(uuid) to authenticated;
