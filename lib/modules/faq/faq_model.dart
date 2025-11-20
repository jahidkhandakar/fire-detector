class FaqQuestion {
  final String id;
  final String question;
  final String answer;
  final List<String> answerSteps;

  FaqQuestion({
    required this.id,
    required this.question,
    required this.answer,
    required this.answerSteps,
  });

  factory FaqQuestion.fromJson(Map<String, dynamic> json) {
    final steps = json['answer_steps'];
    return FaqQuestion(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      answerSteps: steps is List
          ? steps.map((e) => e.toString()).toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'answer_steps': answerSteps,
    };
}

class FaqCategory {
  final String id;
  final String title;
  final int order;
  final List<FaqQuestion> questions;

  FaqCategory({
    required this.id,
    required this.title,
    required this.order,
    required this.questions,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) {
    final qList = json['questions'];
    return FaqCategory(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      order: (json['order'] ?? 0) is int
          ? json['order'] as int
          : int.tryParse(json['order'].toString()) ?? 0,
      questions: qList is List
          ? qList
              .map((e) => FaqQuestion.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : <FaqQuestion>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'order': order,
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

class FaqModel {
  final List<FaqCategory> categories;

  FaqModel({required this.categories});

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    final catList = json['categories'];
    final categories = catList is List
        ? catList
            .map((e) => FaqCategory.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList()
        : <FaqCategory>[];

    // Ensure sorted by order
    categories.sort((a, b) => a.order.compareTo(b.order));

    return FaqModel(categories: categories);
  }

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}
