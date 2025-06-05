import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:quiz_app/models/question.dart';
import 'package:quiz_app/services/api_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool isAnswered = false;
  List<Question> questions = [];
  bool isLoading = true;
  String? error;
  int secondsRemaining = 60;
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    await _initHive();
    await _checkConnectivity();
    await _fetchQuestions();
    _listenToConnectivity();
  }

  Future<void> _initHive() async {
    print('QuizScreen: Initializing Hive');
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(QuestionAdapter().typeId)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    await Hive.openBox<Question>('questions');
    print(
        'QuizScreen: Hive initialized, box length: ${Hive.box<Question>('questions').length}');
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = connectivityResult != ConnectivityResult.none;
    });
    print('QuizScreen: Connectivity check - isOnline: $isOnline');
  }

  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final isOnline = result != ConnectivityResult.none;
      setState(() {
        this.isOnline = isOnline;
      });
      print('QuizScreen: Connectivity changed - isOnline: $isOnline');
      if (isOnline) {
        _fetchQuestions(forceSync: true); // Sync when back online
      }
    });
  }

  Future<void> _fetchQuestions({bool forceSync = false}) async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      questions = await ApiService.fetchQuestions(forceSync: forceSync);
      if (!mounted) return;
      setState(() {
        isLoading = false;
        currentQuestionIndex = 0;
        score = 0;
        selectedAnswer = null;
        isAnswered = false;
        secondsRemaining = 60;
      });
      print('QuizScreen: Fetched ${questions.length} questions');
    } catch (e) {
      if (!mounted) return;
      final box = Hive.box<Question>('questions');
      setState(() {
        isLoading = false;
        error = isOnline
            ? 'Failed to fetch questions. Please try again.'
            : 'No internet connection. ${box.isEmpty ? 'No questions stored locally.' : 'Loading from local storage failed.'}';
      });
      print('QuizScreen: Fetch error: $e');
    }
  }

  void goToNextQuestion() {
    final currentQuestion = questions[currentQuestionIndex];
    if (selectedAnswer != null &&
        selectedAnswer == currentQuestion.correctAnswer) {
      score++;
    }
    setState(() {
      selectedAnswer = null;
      isAnswered = false;
      secondsRemaining = 60; // Reset timer for the next question
    });
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: score,
            totalQuestions: questions.length,
          ),
        ),
      );
    }
  }

  void selectAnswer(String answer) {
    if (!isAnswered) {
      setState(() {
        selectedAnswer = answer;
        isAnswered = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error!,
                style: GoogleFonts.lato(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _fetchQuestions(forceSync: true),
                child: Text('Retry', style: GoogleFonts.lato()),
              ),
            ],
          ),
        ),
      );
    }
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available')),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Question ${currentQuestionIndex + 1}/${questions.length}',
          style: GoogleFonts.lato(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TimerWidget(
              key: ValueKey(
                  currentQuestionIndex), // Recreate widget for each question
              initialSeconds: secondsRemaining,
              onTimeout: goToNextQuestion,
              isAnswered: isAnswered,
            ),
            const SizedBox(height: 20),
            Text(
              currentQuestion.question ?? 'No question available',
              style:
                  GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...(currentQuestion.options ?? []).map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: isAnswered ? null : () => selectAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAnswered
                        ? (option == currentQuestion.correctAnswer
                            ? Colors.green
                            : (option == selectedAnswer
                                ? Colors.red
                                : Colors.grey.shade300))
                        : Colors.blue,
                    padding: const EdgeInsets.all(16),
                    disabledBackgroundColor: isAnswered
                        ? (option == currentQuestion.correctAnswer
                            ? Colors.green
                            : (option == selectedAnswer
                                ? Colors.red
                                : Colors.grey.shade300))
                        : Colors.blue,
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: isAnswered ? Colors.white : Colors.white,
                    ),
                  ),
                ),
              );
            }),
            if (isAnswered && currentQuestion.explanation != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  'Explanation: ${currentQuestion.explanation}',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.blue.shade900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (isAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: goToNextQuestion,
                  child: Text(
                    currentQuestionIndex < questions.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: GoogleFonts.lato(fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TimerWidget extends StatefulWidget {
  final int initialSeconds;
  final bool isAnswered;
  final VoidCallback onTimeout;

  const TimerWidget({
    required this.initialSeconds,
    required this.onTimeout,
    required this.isAnswered,
    super.key,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int secondsRemaining;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    secondsRemaining = widget.initialSeconds;
    if (!widget.isAnswered) {
      startTimer();
    }
  }

  void startTimer() {
    timer?.cancel(); // Cancel any existing timer
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0 && !widget.isAnswered) {
        setState(() {
          secondsRemaining--;
        });
      } else if (secondsRemaining == 0 && !widget.isAnswered) {
        timer.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnswered != oldWidget.isAnswered) {
      if (widget.isAnswered) {
        timer?.cancel(); // Stop timer when answered
      } else {
        secondsRemaining = widget.initialSeconds;
        startTimer(); // Restart timer for new question
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Time: $secondsRemaining s',
      style: GoogleFonts.lato(fontSize: 18, color: Colors.red),
      textAlign: TextAlign.right,
    );
  }
}
