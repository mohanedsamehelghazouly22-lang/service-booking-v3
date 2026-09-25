import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.peach, appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.ink, title: const Text('Provider dashboard', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))), body: ListView(padding: const EdgeInsets.all(20), children: [Row(children: [_metric('Today', '12'), const SizedBox(width: 12), _metric('Pending', '4')]), const SizedBox(height: 20), _section('Today\'s operations', Icons.calendar_today_outlined), _section('Pending bookings', Icons.pending_actions), _section('Assigned locations', Icons.location_on_outlined), _section('Booking table', Icons.table_rows_outlined)]));
  Widget _metric(String a, String b) => Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(b, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)), Text(a, style: const TextStyle(color: Colors.white60))])));
  Widget _section(String t, IconData i) => Card(color: AppColors.ink, margin: const EdgeInsets.only(bottom: 12), child: ListTile(leading: Icon(i, color: AppColors.orange), title: Text(t, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: const Icon(Icons.chevron_right)));
}
