import 'package:hive/hive.dart';

part 'question.g.dart';

@HiveType(typeId: 0)
class Question extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  String? question;

  @HiveField(2)
  List<String>? options;

  @HiveField(3)
  String? correctAnswer;

  @HiveField(4)
  String? explanation;

  Question({
    this.id,
    this.question,
    this.options,
    this.correctAnswer,
    this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] as String?,
      question: json['question'] as String?,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      correctAnswer: json['correctAnswer'] as String?,
      explanation: json['explanation'] as String?,
    );
  }
}
