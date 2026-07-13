import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/service/category_service.dart';
import 'package:niemyetdientu/utils/idle_manager.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      IdleManager.start(); // 👈 không cần context
    });
  }

  void showVoicePopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black54, // nền mờ TV
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 900, // TV rộng nhưng không full
              maxHeight: 1200, // 👈 giữ “lưng lưng”
            ),
            child: Material(
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: const VoiceAssistantPopup(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    final bool isTV = width >= 1200;

    final double padding = isTV ? 32 : 16;
    final double spacing = isTV ? 24 : 12;
    final double searchHeight = isTV ? 72 : 48;
    final double searchFont = isTV ? 22 : 14;
    final double titleSize = isTV ? 28 : 20;
    final double buttonSize = isTV ? 100 : width * 0.14;

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Danh mục thủ tục",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
        ),
      ),

      body: Stack(
        children: [
          Column(
            children: [
              /// 🔍 SEARCH
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  padding,
                  padding,
                  spacing,
                ),
                child: SizedBox(
                  height: searchHeight,
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(fontSize: searchFont),
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm nhóm lĩnh vực",
                      hintStyle: TextStyle(fontSize: searchFont),
                      prefixIcon: Icon(
                        Icons.search,
                        size: isTV ? 28 : 20,
                        color: Colors.grey,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: isTV ? 28 : 20),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = "";
                              }),
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: isTV ? 20 : 12,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isTV ? 20 : 12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isTV ? 20 : 12),
                        borderSide: BorderSide(
                          color: Colors.blue.shade400,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),

              /// 📦 GRID (LUÔN 2 CỘT)
              Expanded(
                child: FutureBuilder<List<CategoryModel>>(
                  future: _futureCategories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Lỗi: ${snapshot.error}"));
                    }

                    final categories = snapshot.data ?? [];

                    final filteredItems = categories.where((item) {
                      return item.title.toLowerCase().contains(
                        _query.toLowerCase(),
                      );
                    }).toList();

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: GridView.builder(
                        itemCount: filteredItems.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 🔥 LUÔN 2 CỘT
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: isTV ? 4.5 : 3.4,
                        ),
                        itemBuilder: (context, index) {
                          return CategoryCard(
                            category: filteredItems[index],
                            height: isTV ? 160 : 96,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          /// 🤖 NÚT CHATBOT (GIỮA MÀN BÊN PHẢI)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: isTV ? 40 : 16),
              child: GestureDetector(
                onTap: showVoicePopup,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: isTV ? 30 : 20,
                        spreadRadius: isTV ? 8 : 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/bot.svg',
                      width: buttonSize * 0.45,
                      height: buttonSize * 0.45,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
