import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSubmitting = false;

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
                                Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeSetting>(
              value: themeManager.currentSetting,
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
                  child: Text('System Default'),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Leave Feedback'),
            subtitle: const Text('Help us improve the app'),
            onTap: _showFeedbackDialog,
          ),
        ],
      ),
    );
  }
}
