import 'package:flutter/material.dart';

class AiMatchScreen extends StatelessWidget {
  final Map<String, dynamic> matchResult;

  const AiMatchScreen({super.key, required this.matchResult});

  @override
  Widget build(BuildContext context) {
    final int score = matchResult['score'] ?? 0;
    final String explanation = matchResult['explanation'] ?? 'No explanation provided.';
    final List<dynamic> matchingSkills = matchResult['matching_skills'] ?? [];
    final List<dynamic> missingSkills = matchResult['missing_skills'] ?? [];

    Color scoreColor;
    if (score < 40) {
      scoreColor = Colors.red;
    } else if (score < 70) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.green;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Match Result'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withValues(alpha: 0.1),
                    border: Border.all(color: scoreColor, width: 4),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'Match',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.insights, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Advisor Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      explanation,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (matchingSkills.isNotEmpty) ...[
                const Text(
                  'Matching Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: matchingSkills.map((skill) {
                    return Chip(
                      label: Text(skill.toString()),
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.green),
                      labelStyle: const TextStyle(color: Colors.green),
                      avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
              if (missingSkills.isNotEmpty) ...[
                const Text(
                  'Missing Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missingSkills.map((skill) {
                    return Chip(
                      label: Text(skill.toString()),
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      side: const BorderSide(color: Colors.orange),
                      labelStyle: const TextStyle(color: Colors.orange),
                      avatar: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
