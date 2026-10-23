import 'package:flutter/material.dart';

import 'info_page.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'About Us',
      headline: 'Our Mission',
      icon: Icons.flag_outlined,
      sections: [
        InfoSection(
          icon: Icons.favorite,
          title: 'The Passion',
          body:
              'We are a team passionate about crafting engaging location-based gaming experiences. Our mission is to connect players with a dynamic virtual world where they can explore, discover monsters, and engage in meaningful interaction.',
        ),
        InfoSection(
          icon: Icons.smartphone,
          title: 'The Interface',
          body:
              'Through a simple, intuitive, and modern user interface, the app allows users to track their progress, catch diverse creatures, and connect with other adventurers.',
        ),
        InfoSection(
          icon: Icons.cloud,
          title: 'The Tech',
          body:
              'This project represents the culmination of our efforts in combining advanced cloud technology, robust mobile design, and innovative, location-dependent gameplay into a single, cohesive experience.',
        ),
      ],
    );
  }
}
