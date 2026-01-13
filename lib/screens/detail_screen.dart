import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/procedure_detail_model.dart';
import 'package:niemyetdientu/service/procedure_service.dart';
import 'package:niemyetdientu/widgets/document_card.dart';
import 'package:niemyetdientu/widgets/info_section.dart';

class DetailScreen extends StatefulWidget {
  final String code;

  const DetailScreen({super.key, required this.code});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ProcedureDetail? detail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final result = await ProcedureService.fetchProcedureDetail(widget.code);
      setState(() {
        detail = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (detail == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy dữ liệu')),
      );
    }

    // ==== Chuẩn bị dữ liệu hiển thị ====
    final sections = [
      {'title': 'Mã thủ tục', 'content': detail!.code},
      {'title': 'Tên thủ tục', 'content': detail!.displayName},
      {'title': 'Mô tả', 'content': detail!.description ?? 'Không có mô tả'},
      {
        'title': 'Yêu cầu thực hiện',
        'content': detail!.requirementsForImplementation ?? '—',
      },
      {
        'title': 'Kết quả thực hiện',
        'content': detail!.implementationResult ?? '—',
      },
      {
        'title': 'Cơ quan thực hiện',
        'content': detail!.competentAgencyId?[1] ?? '—',
      },
      {'title': 'Ngày tạo', 'content': detail!.createDate ?? '—'},
    ];

    final documents = <Map<String, String>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(detail!.displayName, style: const TextStyle(fontSize: 42)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth ~/ 300).clamp(1, 3);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== Các phần thông tin ====
                for (var section in sections) ...[
                  InfoSection(
                    title: section['title']!,
                    content: section['content']!,
                  ),
                  const SizedBox(height: 10),
                ],

                const Divider(height: 32),
                Text(
                  "Thành phần hồ sơ",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Bao gồm:", style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 12),

                // ==== GridView hồ sơ ====
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return DocumentCard(
                      name: doc['name'] ?? '',
                      link: doc['link'] ?? '',
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
