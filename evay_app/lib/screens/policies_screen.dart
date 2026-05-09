import 'package:flutter/material.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Policies content goes here')),
      ),
    );
  }
}
