import 'package:flutter/material.dart';

class BirdDetailsPage extends StatelessWidget {
  final Map<String, dynamic> bird;

  const BirdDetailsPage({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bird['common_name'] ?? 'Bird Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bird['common_name'] ?? '',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              bird['scientific_name'] ?? '',
              style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
            ),

            const SizedBox(height: 16),

            _section("Family", bird['family']),
            _section("Description", bird['description']),
            _section("Abundance Index", bird['abundance_index']),
            _section("Habitat", bird['habitat']),
            _section("Behavior", bird['behavior']),
            _section("Diet", bird['diet']),
            _section("Nesting", bird['nesting']),
            _section("Conservation Status", bird['conservation_status']),
            _section("Size", bird['size']),
            _section("Color", bird['color']),
            _section("Wing Shape", bird['wing_shape']),
            _section("Tail Shape", bird['tail_shape']),
            _section("Call Pattern", bird['call_pattern']),
            _section("Call Type", bird['call_type']),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(value.toString()),
        ],
      ),
    );
  }
}
