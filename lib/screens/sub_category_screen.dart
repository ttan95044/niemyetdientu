import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/model/procedure_model.dart';
import 'package:niemyetdientu/screens/detail_screen.dart';
import 'package:niemyetdientu/service/procedure_service.dart';
import 'package:niemyetdientu/widgets/voice_assistant_popup.dart';

class SubCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const SubCategoryScreen({super.key, required this.category});

  @override
  State<SubCategoryScreen> createState() => _SubCategoryScreenState();
}

class _SubCategoryScreenState extends State<SubCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  bool _isLoading = true;
  List<ProcedureModel> _procedures = [];

  @override
  void initState() {
    super.initState();
    loadProcedures();
  }

  Future<void> loadProcedures() async {
    try {
      final data = await ProcedureService.fetchProceduresByFieldCode(
        widget.category.code,
      );

      // Loại bỏ các phần tử trùng code
      final uniqueProcedures = <String, ProcedureModel>{};

      for (final item in data) {
        uniqueProcedures[item.code] = item;
      }

      setState(() {
        _procedures = uniqueProcedures.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
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

    // 🎯 SIZE CONFIG
    final double padding = isTV ? 32 : 16;
    final double spacing = isTV ? 24 : 16;
    final double searchHeight = isTV ? 72 : 48;
    final double searchFont = isTV ? 22 : 14;
    final double itemFont = isTV ? 22 : 16;
    final double titleSize = isTV ? 28 : 18;
    final double buttonSize = isTV ? 100 : width * 0.12;

    final Color borderColor = Color(int.parse(widget.category.color));

    final filtered = _procedures
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: borderColor,
        foregroundColor: Colors.white,
        title: Text(
          widget.category.title,
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),

      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    /// 🔍 SEARCH
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: SizedBox(
                        height: searchHeight,
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: searchFont),
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm thủ tục...",
                            hintStyle: TextStyle(fontSize: searchFont),
                            prefixIcon: Icon(
                              Icons.search,
                              size: isTV ? 28 : 20,
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: isTV ? 28 : 20,
                                    ),
                                    onPressed: () => setState(() {
                                      _searchController.clear();
                                      _query = "";
                                    }),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: isTV ? 20 : 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                isTV ? 20 : 12,
                              ),
                            ),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                      ),
                    ),

                    /// 📦 GRID (1 HÀNG 3 CÁI TRÊN TV)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = isTV
                              ? 3 // 🔥 TV: 3 item / row
                              : (constraints.maxWidth ~/ 300).clamp(1, 2);

                          return GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: padding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: isTV ? 3.5 : 3.2,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final p = filtered[index];

                              return Material(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    isTV ? 20 : 16,
                                  ),
                                  side: BorderSide(
                                    color: borderColor,
                                    width: isTV ? 2 : 1.5,
                                  ),
                                ),
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    isTV ? 20 : 16,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DetailScreen(code: p.code),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTV ? 20 : 12,
                                      vertical: isTV ? 16 : 10,
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: itemFont,
                                          fontWeight: FontWeight.w600,
                                          color: borderColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),

          /// 🤖 BOT (GIỮA BÊN PHẢI)
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
