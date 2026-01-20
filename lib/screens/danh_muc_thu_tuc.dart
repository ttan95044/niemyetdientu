import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/service/category_service.dart';
import 'package:niemyetdientu/widgets/category_card.dart';
import 'package:niemyetdientu/widgets/voice_assistant_popup.dart';

class DanhMucThuTucPage extends StatefulWidget {
  const DanhMucThuTucPage({super.key});

  @override
  State<DanhMucThuTucPage> createState() => _DanhMucThuTucPageState();
}

class _DanhMucThuTucPageState extends State<DanhMucThuTucPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  late Future<List<CategoryModel>> _futureCategories;

  @override
  void initState() {
    super.initState();
    _futureCategories = CategoryService.fetchCategories();
  }

  void showVoicePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // để viền bo đẹp hơn
      builder: (context) {
        return FractionallySizedBox(
          widthFactor: 1,
          heightFactor:
              0.85, // 👈 85% chiều cao màn hình (giảm nếu muốn thấp hơn)
          child: const VoiceAssistantPopup(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Danh mục thủ tục",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 42,
          ),
        ),
      ),

      body: Column(
        children: [
          // 🔎 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm nhóm lĩnh vực",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.blue.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),

          // 📋 Grid danh mục (API)
          Expanded(
            child: FutureBuilder<List<CategoryModel>>(
              future: _futureCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Lỗi tải dữ liệu: ${snapshot.error}"),
                  );
                }

                final categories = snapshot.data ?? [];
                final filteredItems = categories
                    .where(
                      (item) => item.title.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                    )
                    .toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = (constraints.maxWidth ~/ 270).clamp(
                        1,
                        6,
                      );
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          return CategoryCard(category: filteredItems[index]);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: FloatingActionButton(
              heroTag: "ai_button",
              backgroundColor: Colors.blue.shade600,
              onPressed: showVoicePopup,
              child: SvgPicture.asset(
                'assets/icons/bot.svg',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
