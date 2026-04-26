import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme_manager.dart';
import 'ui_components.dart';
import 'about_us_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSubmitting = false;

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Leave Feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: feedbackController,
                    maxLines: 5,
                    enabled: !_isSubmitting,
                    decoration: const InputDecoration(
                      hintText: 'Tell us what you think...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final feedback = feedbackController.text.trim();
                          if (feedback.isNotEmpty) {
                            setDialogState(() => _isSubmitting = true);
                            try {
                              // If you haven't enabled anonymous sign-in or signed in, 
                              // ensure your Firestore rules allow public writes.
                              await FirebaseFirestore.instance
                                  .collection('feedback')
                                  .add({
                                'text': feedback,
                                'timestamp': FieldValue.serverTimestamp(),
                                'platform': Theme.of(context).platform.toString(),
                              });
                              
                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Thank you for your feedback!')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                // This is usually where the "permission denied" error is caught.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Permission denied: Please check Firestore Rules.')),
                                );
                                debugPrint("Firestore Error: $e");
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(() => _isSubmitting = false);
                              }
                            }
                          }
                        },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('SUBMIT'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                : [Colors.grey[50]!, Colors.grey[200]!],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                opacity: isDarkMode ? 0.05 : 0.15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Appearance",
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: isDarkMode ? TechColors.primary : Colors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.palette_rounded, color: isDarkMode ? Colors.white70 : Colors.black87),
                      title: const Text('App Theme'),
                      trailing: DropdownButton<ThemeSetting>(
                        value: themeManager.currentSetting,
                        underline: const SizedBox(),
                        dropdownColor: isDarkMode ? const Color(0xFF1A2A30) : Colors.white,
                        onChanged: (ThemeSetting? newValue) {
                          if (newValue != null) {
                            setState(() {
                              themeManager.setTheme(newValue);
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeSetting.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeSetting.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeSetting.dark,
                            child: Text('Dark'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                opacity: isDarkMode ? 0.05 : 0.15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Support",
                      style: TextStyle(
                        fontSize: 14, 
                        fontWeight: FontWeight.bold, 
                        color: isDarkMode ? TechColors.primary : Colors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.feedback_rounded, color: isDarkMode ? Colors.white70 : Colors.black87),
                      title: const Text('Leave Direct Feedback'),
                      subtitle: const Text('Help us improve the app'),
                      onTap: _showFeedbackDialog,
                    ),
                    const Divider(height: 32, color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline_rounded, color: isDarkMode ? Colors.white70 : Colors.black87),
                      title: const Text('About Us'),
                      subtitle: const Text('Exdreme Dev LLC'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutUsScreen()),
                        );
                      },
                    ),
                    const Divider(height: 32, color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.privacy_tip_rounded, color: isDarkMode ? Colors.white70 : Colors.black87),
                      title: const Text('Privacy Policy'),
                      subtitle: const Text('Read our data policy'),
                      onTap: () => _launchUrl('https://exdremedev.com/dakulator-privacy'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

