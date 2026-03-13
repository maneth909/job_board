import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

final groqServiceProvider = Provider((ref) => GroqService(supabase));

class GroqService {
  final SupabaseClient supabase;
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  GroqService(this.supabase);

  Future<String> _callGroq({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.3,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not found in .env');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': temperature,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to call Groq API: ${response.statusCode} - ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }

  Future<String> generateApplicationMessage({
    required String jobseekerName,
    required String university,
    required String skills,
    required String jobTitle,
    required String companyName,
    required String cvUrl,
  }) async {
    const systemPrompt =
        '''You are a professional job application assistant. Write a short, polite Telegram application message in 3-4 sentences. Be professional but friendly. Always include the CV link at the end. Do not use emojis. Do not use formal letter format.''';

    final userMessage =
        '''
Jobseeker Name: $jobseekerName
University: $university
Skills: $skills
Job Title: $jobTitle
Company Name: $companyName
CV Link: $cvUrl
''';

    return _callGroq(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.5,
    );
  }

  Future<Map<String, dynamic>> getCVMatchScore({
    required String cvText,
    required String jobDescription,
  }) async {
    const systemPrompt =
        '''You are a supportive, enthusiastic career advisor AI helping a university student. Analyze their CV against the job description.
Return ONLY a valid JSON object. No conversational text before or after. No markdown formatting blocks like ```json.
Format the JSON exactly like this:
{
  "score": 75,
  "explanation": "🌟 **Great potential!** Here is a quick breakdown:\\n• You already have a strong foundation in X and Y.\\n• Your project experience aligns well with their needs.\\n💡 **Next Step:** To be a top candidate, try to familiarize yourself with Z.",
  "matching_skills": ["skill1", "skill2"],
  "missing_skills": ["skill3"]
}
Rules for the 'explanation' field:
- MUST include appropriate emojis (🌟, 💡, 🚀, 🎯, etc.).
- MUST use the bullet point character (•) and newline characters (\\n) to make it easy to read on a mobile screen.
- Keep the tone encouraging, realistic, and completely free of complex corporate jargon. Keep it under 4 short lines.''';
    final userMessage =
        '''
Job Description:
$jobDescription

CV Text:
$cvText
''';

    final rawString = await _callGroq(
      systemPrompt: systemPrompt,
      userMessage: userMessage,
      temperature: 0.2,
    );

    final startIndex = rawString.indexOf('{');
    final endIndex = rawString.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
      final cleanString = rawString.substring(startIndex, endIndex + 1);
      return jsonDecode(cleanString) as Map<String, dynamic>;
    } else {
      throw const FormatException(
        'Failed to extract valid JSON from Groq response.',
      );
    }
  }

  Future<Map<String, dynamic>> getAndCacheCVMatchScore({
    required String jobId,
    required String cvText,
    required String jobDescription,
  }) async {
    final parsedJson = await getCVMatchScore(
      cvText: cvText,
      jobDescription: jobDescription,
    );

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    await supabase.from('cv_matches').upsert({
      'job_id': jobId,
      'jobseeker_id': currentUser.id,
      'score': parsedJson['score'],
      'match_data': parsedJson,
    }, onConflict: 'job_id, jobseeker_id');

    return parsedJson;
  }

  Future<String> simplifyJobDescription(String jobDescription) async {
    const systemPrompt =
        '''You are an expert career advisor. Simplify the following corporate job description into plain, easy-to-understand English for a university student. Return a maximum of 6 concise bullet points highlighting the core responsibilities and requirements. Do not include any introductory or concluding text.''';

    return _callGroq(
      systemPrompt: systemPrompt,
      userMessage: jobDescription,
      temperature: 0.3,
    );
  }
}
