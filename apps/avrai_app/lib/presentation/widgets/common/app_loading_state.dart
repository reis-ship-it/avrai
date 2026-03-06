import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  final String label;

  const AppLoadingState({
    super.key,
    this.label = 'Loading',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(label),
        ],
      ),
    );
  }
}
