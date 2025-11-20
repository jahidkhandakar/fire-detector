import 'package:get/get.dart';
import 'faq_model.dart';
import 'faq_service.dart';
import '/others/errors/app_error_handler.dart';

class FaqController extends GetxController {
  final FaqService _service = FaqService();

  var faq = Rxn<FaqModel>();
  var isLoading = false.obs;
  var error = ''.obs;

  //------------------- 🔎 search state ------------------
  var searchQuery = ''.obs;
  var filteredCategories = <FaqCategory>[].obs;

  Future<void> loadFaq({required String apiUrl}) async {
    try {
      isLoading(true);
      error('');

      final data = await _service.fetchFaq(apiUrl: apiUrl);
      faq.value = data;

      // initial: no filter → show all categories
      _applyFilter();
    } catch (e, st) {
      // Normalize everything into AppException
      final appEx = AppException.from(e, st);

      // For showing inline error text on page (if you use it)
      error(appEx.toUserMessage());

      // Also trigger global UI handler (snackbar)
      AppErrorHandler.handle(appEx, stackTrace: st);
    } finally {
      isLoading(false);
    }
  }

  //--------- Called from UI on each search text change ---------
  void setSearchQuery(String query) {
    searchQuery(query);
    _applyFilter();
  }

  void _applyFilter() {
    final data = faq.value;
    if (data == null) {
      filteredCategories.clear();
      return;
    }

    final q = searchQuery.value.trim().toLowerCase();

    // if no query, show everything as-is
    if (q.isEmpty) {
      filteredCategories.assignAll(data.categories);
      return;
    }

    final List<FaqCategory> result = [];

    for (final cat in data.categories) {
      // filter questions inside this category
      final List<FaqQuestion> matchedQuestions = [];

      for (final fq in cat.questions) {
        final inQuestion = fq.question.toLowerCase().contains(q);
        final inAnswer = fq.answer.toLowerCase().contains(q);
        final inSteps =
            fq.answerSteps.any((s) => s.toLowerCase().contains(q));
        final inCategoryTitle = cat.title.toLowerCase().contains(q);

        if (inQuestion || inAnswer || inSteps || inCategoryTitle) {
          matchedQuestions.add(fq);
        }
      }

      if (matchedQuestions.isNotEmpty) {
        result.add(
          FaqCategory(
            id: cat.id,
            title: cat.title,
            order: cat.order,
            questions: matchedQuestions,
          ),
        );
      }
    }

    filteredCategories.assignAll(result);
  }
}
