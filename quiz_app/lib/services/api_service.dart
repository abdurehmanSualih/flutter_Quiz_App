import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_app/models/question.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String apiKey = 'your-secret-admin-key';

  static Future<List<Question>> fetchQuestions({bool forceSync = false}) async {
    final box = Hive.box<Question>('questions');
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOnline = connectivityResult != ConnectivityResult.none;

    print(
        'ApiService: isOnline=$isOnline, forceSync=$forceSync, box.length=${box.length}');

    if (isOnline && (forceSync || box.isEmpty)) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/questions'),
          headers: {'x-api-key': apiKey},
        ).timeout(const Duration(seconds: 10));

        print(
            'ApiService: HTTP GET $baseUrl/questions - Status: ${response.statusCode}, Body: ${response.body}');

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (data.isEmpty) {
            throw Exception('API returned empty question list');
          }
          final questions =
              data.map((json) => Question.fromJson(json)).toList();

          // Clear and store questions
          await box.clear();
          await box.addAll(questions);
          await box.flush(); // Ensure data is written to disk
          print('ApiService: Hive questions updated: ${box.length}');
          // Verify storage
          final storedQuestions = box.values.toList();
          print(
              'ApiService: Verified Hive storage: ${storedQuestions.length} questions');
          return questions;
        } else {
          throw Exception(
              'Failed to fetch questions: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('ApiService: Failed to fetch questions: $e');
        if (box.isNotEmpty) {
          print(
              'ApiService: Loading questions from Hive: ${box.length} questions');
          return box.values.toList();
        }
        throw Exception(
            'Failed to fetch questions and no local data available: $e');
      }
    } else {
      if (box.isNotEmpty) {
        print(
            'ApiService: Loading questions from Hive: ${box.length} questions');
        final questions = box.values.toList();
        print('ApiService: Retrieved ${questions.length} questions from Hive');
        return questions;
      }
      throw Exception('No internet connection and no local data available');
    }
  }
}
