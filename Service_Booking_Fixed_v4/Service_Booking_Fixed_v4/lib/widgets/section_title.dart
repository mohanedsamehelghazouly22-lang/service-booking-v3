import 'package:flutter/material.dart';
import '../core/theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action});
  final String title;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w900))), if (action != null) Text(action!, style: const TextStyle(color: AppColors.orangeDark, fontWeight: FontWeight.w700))]);
}
