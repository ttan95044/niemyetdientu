import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/procedure_detail_model.dart';
import 'package:niemyetdientu/screens/pdf_viewer_screen.dart';
import 'package:niemyetdientu/service/procedure_service.dart';
import 'package:niemyetdientu/service/template_service.dart';
import 'package:niemyetdientu/widgets/create_pdf.dart';
import 'package:niemyetdientu/widgets/document_card.dart';
import 'package:printing/printing.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(detail!.displayName, style: const TextStyle(fontSize: 42)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Thông tin cơ bản =====
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 500,
                  child: FormRow(label: 'Mã', value: detail!.code),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Niêm yết',
                    value: detail!.isPublished ? 'Có' : 'Không',
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(label: 'Tên', value: detail!.displayName),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Số quyết định',
                    value: detail!.decisionNumber ?? '—',
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Lĩnh vực',
                    value:
                        (detail!.procedureFieldId is List &&
                            detail!.procedureFieldId!.length > 1)
                        ? detail!.procedureFieldId![1].toString()
                        : '—',
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Cấp thực hiện',
                    value:
                        (detail!.implementationLevelId is List &&
                            detail!.implementationLevelId!.length > 1)
                        ? detail!.implementationLevelId![1].toString()
                        : '—',
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Cơ quan thẩm quyền',
                    value:
                        (detail!.competentAgencyId is List &&
                            detail!.competentAgencyId!.length > 1)
                        ? detail!.competentAgencyId![1].toString()
                        : '—',
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: FormRow(
                    label: 'Địa chỉ nhận',
                    value: detail!.receivingAddress ?? '—',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // ===== Trình tự thực hiện =====
            FormRow(
              label: 'Trình tự thực hiện',
              value: detail!.implementationSequence ?? '—',
            ),

            const Divider(),

            // ===== Yêu cầu, điều kiện =====
            FormRow(
              label: 'Yêu cầu, điều kiện',
              value: detail!.requirementsForImplementation ?? '—',
            ),

            const Divider(),

            // ===== Kết quả =====
            FormRow(
              label: 'Kết quả',
              value: detail!.implementationResult ?? '—',
            ),

            const Divider(),

            // ===== Từ khóa =====
            FormRow(label: 'Từ khóa', value: detail!.keywords ?? '—'),

            const SizedBox(height: 32),

            // ===== Thành phần hồ sơ =====
            Text(
              'Thành phần hồ sơ',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 350,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: detail?.components?.length ?? 0,
              itemBuilder: (context, index) {
                final component = detail!.components![index];

                return DocumentCard(
                  name: component.name,
                  originals: component.numberOfOriginals,
                  copies: component.numberOfCopies,

                  /// 👁️ Xem biểu mẫu (PDF)
                  onView: () async {
                    try {
                      final rawTemplateId = component.templateId;

                      // ❌ Không có biểu mẫu
                      if (rawTemplateId == null || rawTemplateId == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu này chưa được cấu hình'),
                          ),
                        );
                        return;
                      }

                      // ❌ Sai format
                      if (rawTemplateId is! List || rawTemplateId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dữ liệu biểu mẫu không hợp lệ'),
                          ),
                        );
                        return;
                      }

                      // ✅ Odoo many2one → lấy ID
                      final int templateId = rawTemplateId[0];

                      final template = await TemplateService.fetchTemplateById(
                        templateId,
                      );

                      // ❌ Không có file PDF
                      if (template.printFileBase64.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu chưa có file PDF'),
                          ),
                        );
                        return;
                      }

                      // ✅ Tạo file PDF
                      final pdfFile = await createPdfFromBase64(
                        template.printFileBase64,
                      );

                      // ✅ Mở màn hình xem PDF
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PdfViewerScreen(filePath: pdfFile.path),
                        ),
                      );
                    } catch (e, s) {
                      debugPrint('[UI] Lỗi xem PDF: $e');
                      debugPrintStack(stackTrace: s);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không thể mở biểu mẫu PDF'),
                        ),
                      );
                    }
                  },

                  /// 🖨️ In biểu mẫu
                  onPrint: () async {
                    try {
                      final rawTemplateId = component.templateId;

                      // ❌ Không có biểu mẫu
                      if (rawTemplateId == null || rawTemplateId == false) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Thủ tục này không có biểu mẫu để in',
                            ),
                          ),
                        );
                        return;
                      }

                      // ❌ Sai format
                      if (rawTemplateId is! List || rawTemplateId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dữ liệu biểu mẫu không hợp lệ'),
                          ),
                        );
                        return;
                      }

                      // ✅ Odoo format: [id, name]
                      final int templateId = rawTemplateId[0];

                      debugPrint('🖨 In biểu mẫu templateId = $templateId');

                      final template = await TemplateService.fetchTemplateById(
                        templateId,
                      );

                      if (template.printFileBase64.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu chưa có file PDF'),
                          ),
                        );
                        return;
                      }

                      final pdfBytes = base64Decode(template.printFileBase64);

                      // ✅ IN – hỗ trợ Windows
                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                        name: template.printFilename.isNotEmpty
                            ? template.printFilename
                            : 'bieu_mau.pdf',
                      );
                    } catch (e) {
                      debugPrint('❌ Lỗi khi in PDF: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể in biểu mẫu')),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FormRow extends StatelessWidget {
  final String label;
  final String value;

  const FormRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: RichText(
              text: TextSpan(
                text: label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
