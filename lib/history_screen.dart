import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'main.dart';
import 'ui_components.dart';

class HistoryScreen extends StatefulWidget {
  final String storageKey;
  final String title;

  const HistoryScreen({super.key, required this.storageKey, required this.title});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await loadHistory(widget.storageKey);
    setState(() {
      _history = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDarkMode ? const Color(0xFF1A2A30) : Colors.white,
                  title: const Text('Clear History'),
                  content: const Text('Are you sure you want to delete all history?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), 
                      child: Text('CLEAR', style: TextStyle(color: isDarkMode ? TechColors.primary : Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await saveHistory(widget.storageKey, []);
                _load();
              }
            },
          )
        ],
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
          child: _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: isDarkMode ? Colors.white24 : Colors.black12),
                      const SizedBox(height: 16),
                      Text('No history yet.', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        opacity: isDarkMode ? 0.05 : 0.15,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          title: Text(
                            _history[index].equation,
                            style: TextStyle(
                              fontSize: 16, 
                              fontFamily: 'monospace',
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.copy_rounded, size: 20, color: isDarkMode ? TechColors.primary : Colors.orange),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _history[index].equation));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[800],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
