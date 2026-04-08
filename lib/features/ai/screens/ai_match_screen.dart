import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AiMatchScreen extends StatelessWidget {
  final Map<String, dynamic> matchResult;

  const AiMatchScreen({super.key, required this.matchResult});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final int score = matchResult['score'] ?? 0;
    final String explanation =
        matchResult['explanation'] ?? 'No analysis provided.';
    final List<dynamic> matchingSkills = matchResult['matching_skills'] ?? [];
    final List<dynamic> missingSkills = matchResult['missing_skills'] ?? [];

    // Keep the score ring colorful
    Color scoreColor;
    if (score < 40) {
      scoreColor = Colors.red;
    } else if (score < 70) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.green;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.chevron_left_rounded,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Match Analysis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 48,
                  ), // Balances the back button for perfect centering
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Score Ring
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: CircularProgressIndicator(
                              value: score / 100,
                              strokeWidth: 12,
                              backgroundColor: scoreColor.withOpacity(0.1),
                              color: scoreColor,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: scoreColor,
                                size: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Match',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // AI Analysis Box
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insights_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'AI Advisor Analysis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Use MarkdownBody to properly render bolding and bullet points
                          MarkdownBody(
                            data: explanation,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                              strong: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              listBullet: TextStyle(color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Matching Skills Section
                    if (matchingSkills.isNotEmpty) ...[
                      Text(
                        'Matching Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: matchingSkills.map((skill) {
                          // Toned down: Uses your primary theme color instead of bright green
                          return _buildSkillTag(
                            text: skill.toString(),
                            color: colorScheme.primary,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            icon: Icons.check_circle_outline_rounded,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Missing Skills Section
                    if (missingSkills.isNotEmpty) ...[
                      Text(
                        'Missing Skills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: missingSkills.map((skill) {
                          // Toned down: Uses a neutral greyish tone instead of bright orange
                          return _buildSkillTag(
                            text: skill.toString(),
                            color: colorScheme.onSurface.withOpacity(0.6),
                            backgroundColor: colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            icon: Icons.remove_circle_outline_rounded,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern tag builder for skills
  Widget _buildSkillTag({
    required String text,
    required Color color,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
