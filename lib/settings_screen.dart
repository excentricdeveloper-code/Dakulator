import 'package:flutter/material.dart';
import 'theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        ],
      ),
    );
  }
}
