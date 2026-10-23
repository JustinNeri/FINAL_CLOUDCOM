import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets.dart';

/// One titled block of text on an [InfoPage].
class InfoSection {
  const InfoSection({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

/// Simple text page (About Us, Privacy Policy) with a header and cards.
class InfoPage extends StatelessWidget {
  const InfoPage({
    super.key,
    required this.title,
    required this.headline,
    required this.icon,
    required this.sections,
  });

  final String title;
  final String headline;
  final IconData icon;
  final List<InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ContentWidth(
            maxWidth: 640,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(child: IconBadge(icon: icon, color: ThemeColors.pokeBlue, size: 72)),
                const SizedBox(height: 14),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                for (final section in sections) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconBadge(icon: section.icon, color: ThemeColors.pokeRed, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(section.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(section.body, style: const TextStyle(color: ThemeColors.textMuted, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Developed by the Might Team',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ThemeColors.textMuted, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
