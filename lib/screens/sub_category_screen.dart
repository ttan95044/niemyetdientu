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
      setState(() {
        _procedures = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = Color(int.parse(widget.category.color));
    final filtered = _procedures
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    void showVoicePopup() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent, // để viền bo đẹp hơn
        builder: (context) {
          return FractionallySizedBox(
            heightFactor:
                0.85, // 👈 85% chiều cao màn hình (giảm nếu muốn thấp hơn)
            child: const VoiceAssistantPopup(),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = MediaQuery.of(context).size.width;
            final double fontSize = screenW >= 1200
                ? 28
                : screenW >= 800
                ? 22
                : 18;
            return Text(
              widget.category.title,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        backgroundColor: borderColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _procedures.isEmpty
          ? const Center(child: Text("Không có thủ tục con nào."))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm thủ tục con...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _query = '';
                              }),
                            )
                          : null,
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
                        borderSide: BorderSide(color: borderColor, width: 1.5),
                      ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = (constraints.maxWidth ~/ 280)
                          .clamp(1, 6);
                      final double tileWidth =
                          (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                          crossAxisCount;
                      final double childAspect =
                          tileWidth / 92; // aim for ~92px height

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspect.clamp(1.8, 4.5),
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1.5),
                            ),
                            elevation: 1,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailScreen(code: p.code),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                                child: Center(
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: borderColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: showVoicePopup,
        child: SvgPicture.asset(
          'assets/icons/bot.svg',
          width: 38,
          height: 38,
          color: Colors.white,
        ),
      ),
    );
  }
}
