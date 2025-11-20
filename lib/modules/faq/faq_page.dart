import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'faq_controller.dart';
import 'faq_model.dart';
import '/others/utils/api.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final FaqController _faqCtrl = Get.put(FaqController());
  final String apiUrl = Api.faq; // '$baseUrl/content/faq/';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _faqCtrl.loadFaq(apiUrl: apiUrl);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ'),
      ),
      body: Obx(() {
        if (_faqCtrl.isLoading.value && _faqCtrl.faq.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_faqCtrl.error.value.isNotEmpty &&
            _faqCtrl.faq.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _faqCtrl.error.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final List<FaqCategory> categories =
            _faqCtrl.filteredCategories;

        return Column(
          children: [
            //----------------- 🔎 Search bar-----------------
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _faqCtrl.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Search FAQ (keywords, questions, topics...)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 4),

            //----------------- List section-----------------
            Expanded(
              child: categories.isEmpty
                  ? const Center(
                      child: Text('No FAQ matched your search.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final FaqCategory category = categories[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent, 
                            ),
                            child: ExpansionTile(
                              title: Text(
                                category.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              children: [
                                const Divider(height: 1),
                                ...category.questions.map(
                                  (q) => _buildQuestionTile(context, q),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
  //------------------ Question Tile Widget ------------------
  Widget _buildQuestionTile(BuildContext context, FaqQuestion q) {
    final hasSteps = q.answerSteps.isNotEmpty;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          q.question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              q.answer,
              style: (Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.yellow[900],
              )) ?? TextStyle(color: Colors.yellow[900]),
            ),
          ),
          if (hasSteps) const SizedBox(height: 8),
          if (hasSteps)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...q.answerSteps.asMap().entries.map(
                  (entry) {
                    final stepIndex = entry.key + 1;
                    final text = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$stepIndex. ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
