import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/service/category_service.dart';
import 'package:niemyetdientu/utils/idle_manager.dart';
import 'package:niemyetdientu/widgets/category_card.dart';
import 'package:niemyetdientu/widgets/voice_assistant_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DanhMucThuTucPage extends StatefulWidget {
  const DanhMucThuTucPage({super.key});

  @override
  State<DanhMucThuTucPage> createState() => _DanhMucThuTucPageState();
}

class _DanhMucThuTucPageState extends State<DanhMucThuTucPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  Future<List<CategoryModel>>? _futureCategories;

  int _companyId = 1;

  final Map<int, String> _companies = {
    1: "Cờ đỏ",
    4: "Châu Thành - Cần Thơ",
    5: "Phú Tân",
  };

  @override
  void initState() {
    super.initState();

    _loadCompany();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      IdleManager.start();
    });
  }

  Future<void> _loadCompany() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCompanyId = prefs.getInt('company_id');

    if (savedCompanyId == null) {
      _companyId = 1;

      if (mounted) {
        await _showCompanyDialog();
      }
    } else {
      _companyId = savedCompanyId;
    }

    _futureCategories = CategoryService.fetchCategories(companyId: _companyId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showCompanyDialog() async {
    int selectedCompanyId = _companyId;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chọn đơn vị"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _companies.entries.map((entry) {
                    return RadioListTile<int>(
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: selectedCompanyId,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCompanyId = value;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();

                await prefs.setInt('company_id', selectedCompanyId);

                _companyId = selectedCompanyId;

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
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
                child: _futureCategories == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<CategoryModel>>(
                        future: _futureCategories,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text("Lỗi: ${snapshot.error}"),
                            );
                          }

                          final categories = [...(snapshot.data ?? [])];

                          // ID ưu tiên (thay bằng ID thật)
                          const priorityIds = [
                            139, // Hộ tịch
                            144, // Văn hóa
                            136, // Thành lập và hoạt động doanh nghiệp
                            117, // Hoạt động xây dựng
                            182, // Nông nghiệp
                            121, // Giáo dục và Đào tạo
                            128, // Đất đai
                          ];

                          categories.sort((a, b) {
                            final indexA = priorityIds.indexOf(a.id);
                            final indexB = priorityIds.indexOf(b.id);

                            // Cả hai đều không nằm trong danh sách ưu tiên
                            if (indexA == -1 && indexB == -1) {
                              return 0;
                            }

                            // a không ưu tiên -> xuống dưới
                            if (indexA == -1) {
                              return 1;
                            }

                            // b không ưu tiên -> xuống dưới
                            if (indexB == -1) {
                              return -1;
                            }

                            // Cả hai đều ưu tiên -> sắp theo thứ tự trong priorityIds
                            return indexA.compareTo(indexB);
                          });

                          final filteredItems = categories.where((item) {
                            return item.title.toLowerCase().contains(
                              _query.toLowerCase(),
                            );
                          }).toList();

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            child: GridView.builder(
                              itemCount: filteredItems.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
