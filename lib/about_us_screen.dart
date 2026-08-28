import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ui_components.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        body: Stack(
          children: [
            // Full screen background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [TechColors.backgroundDark, TechColors.backgroundDark, TechColors.backgroundDarkEnd]
                      : [const Color(0xFF1a2a30), const Color(0xFF0F2027), const Color(0xFF2C5364)],
                ),
              ),
            ),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Custom Header / Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'About Us',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Hero(
                            tag: 'exdreme_logo',
                            child: GlassCard(
                              padding: const EdgeInsets.all(20),
                              opacity: 0.1,
                              child: Image.asset(
                                'image reference/exdreme.png',
                                height: 140,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Exdreme Dev LLC',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: TechColors.primary,
                              letterSpacing: 2.0,
                              shadows: [
                                Shadow(
                                  color: TechColors.primary.withAlpha(100),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Innovating the Future of Apps',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 40),
                          GlassCard(
                            opacity: 0.08,
                            child: Column(
                              children: [
                                const Text(
                                  'We are dedicated to building high-quality, professional tools that simplify complex tasks. Our mission is to empower users through elegant design and advanced functionality.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    height: 1.6,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.language_rounded,
                                  label: 'Visit Our Website',
                                  onPressed: () => _launchUrl('https://exdremedev.com'),
                                  color: TechColors.primary,
                                ),
                                const SizedBox(height: 16),
                                _buildActionButton(
                                  context: context,
                                  icon: Icons.volunteer_activism_rounded,
                                  label: 'Support Us on PayPal',
                                  onPressed: () => _launchUrl('https://paypal.me/Exdremedev'),
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          const Text(
                            '© 2026 Exdreme Dev LLC. All Rights Reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(100)),
            gradient: LinearGradient(
              colors: [color.withAlpha(40), color.withAlpha(15)],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
