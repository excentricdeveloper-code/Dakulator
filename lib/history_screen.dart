import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'main.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear History'),
                  content: const Text('Are you sure you want to delete all history?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CLEAR')),
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
      body: SafeArea(
        child: _history.isEmpty
            ? const Center(child: Text('No history yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _history[index].equation,
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _history[index].equation));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
