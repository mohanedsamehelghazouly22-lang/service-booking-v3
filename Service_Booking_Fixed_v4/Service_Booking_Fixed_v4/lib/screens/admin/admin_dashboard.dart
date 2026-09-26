import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: AppColors.peach, appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: AppColors.ink, title: const Text('Admin console', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w900))), body: GridView.count(padding: const EdgeInsets.all(20), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, children: [_tile('Services', Icons.home_repair_service), _tile('Locations', Icons.location_city), _tile('Providers', Icons.groups), _tile('Assignments', Icons.assignment_ind), _tile('Bookings', Icons.receipt_long), _tile('Availability', Icons.schedule), _tile('Users & roles', Icons.manage_accounts), _tile('Configuration', Icons.settings)]));
  Widget _tile(String t, IconData i) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: AppColors.orange, size: 32), const SizedBox(height: 12), Text(t, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))]));
}
