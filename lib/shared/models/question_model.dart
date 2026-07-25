import 'package:equatable/equatable.dart';

enum AnswerOption { a, b, c, d }

extension AnswerOptionExt on AnswerOption {
  String get label {
    switch (this) {
      case AnswerOption.a: return 'A';
      case AnswerOption.b: return 'B';
      case AnswerOption.c: return 'C';
      case AnswerOption.d: return 'D';
    }
  }

  static AnswerOption fromString(String s) {
    switch (s.toUpperCase()) {
      case 'A': return AnswerOption.a;
      case 'B': return AnswerOption.b;
      case 'C': return AnswerOption.c;
      default: return AnswerOption.d;
    }
  }
}

class QuestionModel extends Equatable {
  final String id;
  final String text;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final AnswerOption correctAnswer;
  final String? explanation;

  const QuestionModel({
    required this.id,
    required this.text,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.explanation,
  });

  String getOption(AnswerOption opt) {
    switch (opt) {
      case AnswerOption.a: return optionA;
      case AnswerOption.b: return optionB;
      case AnswerOption.c: return optionC;
      case AnswerOption.d: return optionD;
    }
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      optionA: json['optionA'] as String,
      optionB: json['optionB'] as String,
      optionC: json['optionC'] as String,
      optionD: json['optionD'] as String,
      correctAnswer: AnswerOptionExt.fromString(json['correctAnswer'] as String? ?? 'A'),
      explanation: json['explanation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctAnswer': correctAnswer.label,
      'explanation': explanation,
    };
  }

  QuestionModel copyWith({
    String? id, String? text, String? optionA, String? optionB,
    String? optionC, String? optionD, AnswerOption? correctAnswer, String? explanation,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      text: text ?? this.text,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  List<Object?> get props => [id, text, optionA, optionB, optionC, optionD, correctAnswer, explanation];
}
