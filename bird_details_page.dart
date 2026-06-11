import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BirdDetailsPage extends StatelessWidget {
  final Map<String, dynamic> bird;

  const BirdDetailsPage({super.key, required this.bird});

  @override
  Widget build(BuildContext context) {
    final String? url = bird['all_about_birds_url'];
    print(bird);
    print(url);

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
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
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

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            if (url != null && url.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(url);

                    print("Launching: $uri");

                    final success = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );

                    print("Success: $success");
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("View Full Species Profile"),
                ),
              ),

            const SizedBox(height: 16),

            const Text(
              "Information adapted from the Cornell Lab of Ornithology's All About Birds.",
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
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
          Text(value.toString(), style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
