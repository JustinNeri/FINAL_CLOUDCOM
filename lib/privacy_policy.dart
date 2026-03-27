import 'package:flutter/material.dart';
import 'theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: ThemeColors.pokeRed,
        elevation: 2,
        title: const Text('PRIVACY POLICY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
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
                _PolicyCard(
                  title: 'Data We Collect',
                  body:
                      'Our priority is to protect the minimal data we receive while ensuring you have a great gameplay experience. HauPokemon collects certain details like location coordinates, account information, and essential game metrics. These data points are vital for rendering game features and maintaining system integrity. Your position data is utilized exclusively to support core mechanics, such as locating in-game creatures and validating actions based on your current physical location.',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _PolicyCard(
                  title: 'How We Use Data',
                  body:
                      'All user data is stored securely and processed only to the extent necessary for the application\'s core functions. By interacting with the app, you provide consent for this use in gameplay, authentication, and continuous system enhancement.',
                  icon: Icons.lock,
                ),
                const SizedBox(height: 16),
                _PolicyCard(
                  title: 'Policy Updates',
                  body:
                      'Should our systems or services undergo updates, this policy will also be revised to ensure clear information regarding data handling changes.',
                  icon: Icons.update,
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

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.title, required this.body, required this.icon});

  final String title;
  final String body;
  final IconData icon;

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
