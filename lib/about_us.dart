import 'package:flutter/material.dart';
import 'theme.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: ThemeColors.pokeRed,
        elevation: 2,
        title: Text('OUR MISSION', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFBF0), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const _MissionCard(
                  icon: Icons.favorite,
                  title: 'The Passion',
                  body:
                      'We are a team passionate about crafting engaging location-based gaming experiences. Our mission is to connect players with a dynamic virtual world where they can explore, discover monsters, and engage in meaningful interaction.',
                ),
                const SizedBox(height: 16),
                const _MissionCard(
                  icon: Icons.smartphone,
                  title: 'The Interface',
                  body:
                      'Through a simple, intuitive, and modern user interface, the app allows users to track their progress, catch diverse creatures, and connect with other adventurers.',
                ),
                const SizedBox(height: 16),
                const _MissionCard(
                  icon: Icons.cloud,
                  title: 'The Tech',
                  body:
                      'This project represents the culmination of our efforts in combining advanced cloud technology, robust mobile design, and innovative, location-dependent gameplay into a single, cohesive experience.',
                ),
                const SizedBox(height: 28),
                Center(
                  child: Text(
                    'Developed by the Might Team',
                    style: TextStyle(
                      color: ThemeColors.pokeYellow,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.pokeBlue.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: ThemeColors.pokeYellow,
            child: Icon(icon, color: ThemeColors.deepNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: ThemeColors.deepNavy, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
