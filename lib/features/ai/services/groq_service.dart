import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final groqServiceProvider = Provider((ref) => GroqService());

class GroqService {
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

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
        'model': 'llama3-8b-instant',
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
        '''You are a career advisor AI. Analyze a CV against a job description. Return ONLY a valid JSON object. No explanation before or after. No markdown. Format: {"score": 75, "explanation": "two sentence summary", "matching_skills": ["skill1"], "missing_skills": ["skill2"]}''';

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
