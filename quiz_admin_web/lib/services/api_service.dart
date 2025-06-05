import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String fallbackUrl = 'http://10.0.2.2:3000/api';
  static const String apiKey = 'your-secret-admin-key';

  // Save JWT token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    print('ApiService: Saved token: $token');
  }

  // Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    print('ApiService: Retrieved token: $token');
    return token;
  }

  // Clear JWT token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    print('ApiService: Cleared token');
  }

  // Signin
  static Future<Map<String, dynamic>> signin(
      String email, String password) async {
    try {
      print(
          'ApiService: Sending signin request: email=$email, url: $baseUrl/auth/signin');
      var response = await http
          .post(
            Uri.parse('$baseUrl/auth/signin'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      print(
          'ApiService: Signin response (primary): ${response.statusCode} ${response.body}');

      // Fallback if primary fails
      if (response.statusCode >= 400) {
        print(
            'ApiService: Retrying signin with fallback URL: $fallbackUrl/auth/signin');
        response = await http
            .post(
              Uri.parse('$fallbackUrl/auth/signin'),
              headers: {'Content-Type': 'application/json'},
              body: json.encode({'email': email, 'password': password}),
            )
            .timeout(const Duration(seconds: 15));
        print(
            'ApiService: Signin response (fallback): ${response.statusCode} ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await saveToken(data['token']);
        return {'user': data['user'], 'token': data['token']};
      } else {
        throw Exception(
            'Failed to sign in: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ApiService: Signin raw error: $e');
      throw Exception('Error signing in: $e');
    }
  }

  static Future<List<Question>> fetchQuestions() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print('ApiService: Fetching questions with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/questions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
          'ApiService: Fetch questions response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load questions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ApiService: Fetch questions error: $e');
      throw Exception('Error fetching questions: $e');
    }
  }

  static Future<Question> addQuestion(Question question) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      final questionData = question.toJson()..remove('id');
      print(
          'ApiService: Adding question with token: $token, data: $questionData');
      final response = await http.post(
        Uri.parse('$baseUrl/questions'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
        body: json.encode(questionData),
      );
      print(
          'ApiService: Add question response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        return Question.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to add question: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ApiService: Add question error: $e');
      throw Exception('Error adding question: $e');
    }
  }

  static Future<Question> updateQuestion(Question question) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print(
          'ApiService: Updating question with token: $token, id: ${question.id}, data: ${question.toJson()}');
      var response = await http
          .put(
            Uri.parse('$baseUrl/questions/${question.id}'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'Authorization': 'Bearer $token',
            },
            body: json.encode(question.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      print(
          'ApiService: Update question response (primary): ${response.statusCode} ${response.body}');

      // Fallback if primary fails
      if (response.statusCode >= 400) {
        print(
            'ApiService: Retrying update with fallback URL: $fallbackUrl/questions/${question.id}');
        response = await http
            .put(
              Uri.parse('$fallbackUrl/questions/${question.id}'),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': apiKey,
                'Authorization': 'Bearer $token',
              },
              body: json.encode(question.toJson()),
            )
            .timeout(const Duration(seconds: 15));
        print(
            'ApiService: Update question response (fallback): ${response.statusCode} ${response.body}');
      }

      if (response.statusCode == 200) {
        return Question.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to update question: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ApiService: Update question raw error: $e');
      throw Exception('Error updating question: $e');
    }
  }

  static Future<void> deleteQuestion(String id) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }
      print('ApiService: Deleting question with token: $token, id: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/questions/$id'),
        headers: {
          'x-api-key': apiKey,
          'Authorization': 'Bearer $token',
        },
      );
      print(
          'ApiService: Delete question response: ${response.statusCode} ${response.body}');
      if (response.statusCode != 204) {
        throw Exception(
            'Failed to delete question: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ApiService: Delete question error: $e');
      throw Exception('Error deleting question: $e');
    }
  }
}
