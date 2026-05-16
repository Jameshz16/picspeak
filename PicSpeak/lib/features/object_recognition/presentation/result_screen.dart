import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String wordId;

  const ResultScreen({super.key, required this.wordId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('ResultScreen TODO: $wordId'),
      ),
    );
  }
}
