import 'package:flutter/material.dart';

import 'info_page.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Privacy Policy',
      headline: 'Your Privacy',
      icon: Icons.privacy_tip_outlined,
      sections: [
        InfoSection(
          icon: Icons.location_on,
          title: 'Data We Collect',
          body:
              'Our priority is to protect the minimal data we receive while ensuring you have a great gameplay experience. HauPokemon collects certain details like location coordinates, account information, and essential game metrics. These data points are vital for rendering game features and maintaining system integrity. Your position data is utilized exclusively to support core mechanics, such as locating in-game creatures and validating actions based on your current physical location.',
        ),
        InfoSection(
          icon: Icons.lock,
          title: 'How We Use Data',
          body:
              'All user data is stored securely and processed only to the extent necessary for the application\'s core functions. By interacting with the app, you provide consent for this use in gameplay, authentication, and continuous system enhancement.',
        ),
        InfoSection(
          icon: Icons.update,
          title: 'Policy Updates',
          body:
              'Should our systems or services undergo updates, this policy will also be revised to ensure clear information regarding data handling changes.',
        ),
      ],
    );
  }
}
