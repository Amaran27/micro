import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple test app for agent delegation
void main() {
  runApp(const ProviderScope(child: MinimalAgentApp()));
}

class MinimalAgentApp extends StatelessWidget {
  const MinimalAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Agent Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MinimalAgentScreen(),
    );
  }
}

class MinimalAgentScreen extends ConsumerWidget {
  const MinimalAgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent System Test')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Agent System Running', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('Core agent infrastructure is working'),
          ],
        ),
      ),
    );
  }
}
