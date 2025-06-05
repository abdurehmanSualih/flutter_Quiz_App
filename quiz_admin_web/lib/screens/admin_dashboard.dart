import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_admin_web/services/api_service.dart';
import '../models/question.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionsController =
      List<TextEditingController>.generate(4, (_) => TextEditingController());
  final _correctAnswerController = TextEditingController();
  final _explanationController = TextEditingController();
  final _editQuestionController = TextEditingController();
  final _editOptionsController =
      List<TextEditingController>.generate(4, (_) => TextEditingController());
  final _editCorrectAnswerController = TextEditingController();
  final _editExplanationController = TextEditingController();
  final _searchController = TextEditingController();
  List<Question> _questions = [];
  List<Question> _filteredQuestions = [];
  bool _isLoading = false;
  bool _isAddFormExpanded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
    _searchController.addListener(_filterQuestions);
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _questions = await ApiService.fetchQuestions();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _filteredQuestions = _questions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _filterQuestions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredQuestions = _questions
          .where((question) =>
              question.question?.toLowerCase().contains(query) ?? false)
          .toList();
    });
  }

  Future<void> _addQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final question = Question(
          id: null,
          question: _questionController.text,
          options: _optionsController.map((c) => c.text).toList(),
          correctAnswer: _correctAnswerController.text,
          explanation: _explanationController.text,
        );
        await ApiService.addQuestion(question);
        if (!mounted) return;
        _clearAddForm();
        await _fetchQuestions();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _editQuestion(Question question) async {
    setState(() {
      _isAddFormExpanded = false;
    });
    _editQuestionController.text = question.question ?? '';
    for (int i = 0; i < 4; i++) {
      _editOptionsController[i].text = question.options?[i] ?? '';
    }
    _editCorrectAnswerController.text = question.correctAnswer ?? '';
    _editExplanationController.text = question.explanation ?? '';

    bool? shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Question', style: GoogleFonts.lato()),
        content: SingleChildScrollView(
          child: Form(
            key: _editFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _editQuestionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a question';
                    }
                    return null;
                  },
                ),
                ...List.generate(
                  4,
                  (index) => TextFormField(
                    controller: _editOptionsController[index],
                    decoration: InputDecoration(
                      labelText: 'Option ${index + 1}',
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter option ${index + 1}';
                      }
                      return null;
                    },
                  ),
                ),
                TextFormField(
                  controller: _editCorrectAnswerController,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter the correct answer';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _editExplanationController,
                  decoration: const InputDecoration(
                    labelText: 'Explanation',
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an explanation';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lato()),
          ),
          ElevatedButton(
            onPressed: () {
              if (_editFormKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: Text('Save', style: GoogleFonts.lato()),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) {
      _clearEditForm();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updatedQuestion = Question(
        id: question.id,
        question: _editQuestionController.text,
        options: _editOptionsController.map((c) => c.text).toList(),
        correctAnswer: _editCorrectAnswerController.text,
        explanation: _editExplanationController.text,
      );
      print('Updating question: ${updatedQuestion.toJson()}');
      await ApiService.updateQuestion(updatedQuestion);
      print('Update question success');
      _clearEditForm();
      if (!mounted) return;
      await _fetchQuestions();
    } catch (e) {
      print('Update question error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _deleteQuestion(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion', style: GoogleFonts.lato()),
        content: Text(
          'Are you sure you want to delete this question?',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.lato()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.lato(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ApiService.deleteQuestion(id);
      if (!mounted) return;
      await _fetchQuestions();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _clearAddForm() {
    _questionController.clear();
    for (var controller in _optionsController) {
      controller.clear();
    }
    _correctAnswerController.clear();
    _explanationController.clear();
    _formKey.currentState?.reset();
  }

  void _clearEditForm() {
    _editQuestionController.clear();
    for (var controller in _editOptionsController) {
      controller.clear();
    }
    _editCorrectAnswerController.clear();
    _editExplanationController.clear();
    _editFormKey.currentState?.reset();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionsController) {
      controller.dispose();
    }
    _correctAnswerController.dispose();
    _explanationController.dispose();
    _editQuestionController.dispose();
    for (var controller in _editOptionsController) {
      controller.dispose();
    }
    _editCorrectAnswerController.dispose();
    _editExplanationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Admin Dashboard',
            style: GoogleFonts.lato(color: Colors.white)),
        backgroundColor: Colors.blue,
        actions: [
          SizedBox(
            width: 200,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  hintStyle: GoogleFonts.lato(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: GoogleFonts.lato(color: Colors.white),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.clearToken();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/signIn');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ExpansionTile(
                      title: Text(
                        'Add New Question',
                        style: GoogleFonts.lato(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: _isAddFormExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _isAddFormExpanded = expanded;
                        });
                      },
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _questionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Question',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter a question';
                                      }
                                      return null;
                                    },
                                  ),
                                  ...List.generate(
                                    4,
                                    (index) => TextFormField(
                                      controller: _optionsController[index],
                                      decoration: InputDecoration(
                                        labelText: 'Option ${index + 1}',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.never,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Enter option ${index + 1}';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  TextFormField(
                                    controller: _correctAnswerController,
                                    decoration: const InputDecoration(
                                      labelText: 'Correct Answer',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter the correct answer';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _explanationController,
                                    decoration: const InputDecoration(
                                      labelText: 'Explanation',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter an explanation';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _clearAddForm,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                        ),
                                        child: Text('Clear',
                                            style:
                                                GoogleFonts.lato(fontSize: 18)),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: _addQuestion,
                                        child: Text('Add Question',
                                            style:
                                                GoogleFonts.lato(fontSize: 18)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Questions',
                      style: GoogleFonts.lato(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _filteredQuestions.isEmpty
                        ? const Center(child: Text('No questions found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredQuestions.length,
                            itemBuilder: (context, index) {
                              final question = _filteredQuestions[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Card(
                                  elevation: 2,
                                  child: ListTile(
                                    title: Text(
                                      question.question ?? 'No question',
                                      style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Options: ${(question.options ?? []).join(', ')}',
                                          style: GoogleFonts.lato(),
                                        ),
                                        Text(
                                          'Correct: ${question.correctAnswer ?? 'None'}',
                                          style: GoogleFonts.lato(),
                                        ),
                                        Text(
                                          'Explanation: ${question.explanation ?? 'None'}',
                                          style: GoogleFonts.lato(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _editQuestion(question),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _deleteQuestion(question.id!),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
