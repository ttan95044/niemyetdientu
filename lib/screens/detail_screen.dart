import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/procedure_detail.dart';
import 'package:niemyetdientu/model/procedure_detail_response.dart';
import 'package:niemyetdientu/screens/pdf_viewer_screen.dart';
import 'package:niemyetdientu/service/procedure_service.dart';
import 'package:niemyetdientu/service/template_service.dart';
import 'package:niemyetdientu/utils/file_helper.dart';
import 'package:niemyetdientu/widgets/create_pdf.dart';
import 'package:niemyetdientu/widgets/document_card.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailScreen extends StatefulWidget {
  final String code;

  const DetailScreen({super.key, required this.code});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ProcedureDetailResponse? response;
  int currentPage = 0;
  final PageController _pageController = PageController();
  bool isLoading = true;

  ProcedureDetail get detail => response!.variants[currentPage];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final result = await ProcedureService.fetchProcedureDetail(widget.code);
      setState(() {
        response = result;
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
    final screenW = MediaQuery.of(context).size.width;
    final bool isTV = screenW >= 1200;

    // 🔥 tăng mạnh font
    final double titleSize = screenW >= 1400
        ? 36
        : screenW >= 1000
        ? 30
        : 24;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (response == null || response!.variants.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy dữ liệu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detail.name,
          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (response!.count > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: isTV ? 12 : 6,
                  runSpacing: isTV ? 12 : 6,
                  children: List.generate(response!.variantCodes.length, (
                    index,
                  ) {
                    final selected = index == currentPage;

                    return ChoiceChip(
                      label: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTV ? 24 : 12,
                          vertical: isTV ? 12 : 6,
                        ),
                        child: Text(
                          response!.variantCodes[index],
                          style: TextStyle(
                            fontSize: isTV ? 28 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    );
                  }),
                ),
              ),
            ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: response!.variants.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final detail = response!.variants[index];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildDetail(context, detail),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 Widget hiển thị một dòng thông tin
Widget _buildDetail(BuildContext context, ProcedureDetail detail) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        padding: const EdgeInsets.all(20), // 🔥 padding lớn hơn
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            detail.variantText != null
                ? FormRow(
                    label: 'Nội dung trường hợp',
                    value: detail.variantText!,
                  )
                : const SizedBox.shrink(),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                if (detail.urlQrcode != null && detail.urlQrcode!.isNotEmpty)
                  Center(
                    child: Column(
                      children: [
                        QrImageView(
                          data: detail.urlQrcode!,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          "Quét mã QR để xem trên điện thoại",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                SizedBox(
                  width: 520,
                  child: FormRow(label: 'Mã', value: detail.code),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Niêm yết',
                    value: detail.isPublished ? 'Có' : 'Không',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            FormRow(label: 'Tên', value: detail.name),

            const SizedBox(height: 12),

            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Số quyết định',
                    value: detail.decisionNumber ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Lĩnh vực',
                    value: detail.procedureField?.name ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Cấp thực hiện',
                    value: detail.implementationLevel?.name ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Cơ quan thẩm quyền',
                    value: detail.competentAgency?.name ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Cơ quan thực hiện',
                    value: detail.implementationAgencies.isEmpty
                        ? '—'
                        : detail.implementationAgencies
                              .map((e) => e.name)
                              .join(', '),
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Đối tượng',
                    value: detail.implementationObjects.isEmpty
                        ? '—'
                        : detail.implementationObjects
                              .map((e) => e.name)
                              .join(', '),
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Địa chỉ nhận',
                    value: detail.receivingAddress ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Loại thủ tục',
                    value: detail.procedureType?.name ?? '—',
                  ),
                ),
                SizedBox(
                  width: 520,
                  child: FormRow(
                    label: 'Mã hiển thị',
                    value: detail.displayCode,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),
            const Divider(),

            FormRow(
              label: 'Trình tự thực hiện',
              value: detail.implementationSequence ?? '—',
            ),

            const Divider(),

            FormRow(
              label: 'Yêu cầu, điều kiện',
              value: detail.requirementsForImplementation ?? '—',
            ),

            const Divider(),

            FormRow(
              label: 'Kết quả',
              value: detail.implementationResult ?? '—',
            ),

            const Divider(),

            FormRow(label: 'Từ khóa', value: detail.keywords ?? '—'),

            const SizedBox(height: 36),

            Text(
              'Thành phần hồ sơ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 26, // 🔥 to hơn
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.35,
              ),
              itemCount: detail.components.length,
              itemBuilder: (context, index) {
                final component = detail.components[index];

                return DocumentCard(
                  name: component.name,
                  originals: component.numberOfOriginals,
                  copies: component.numberOfCopies,

                  onView: () async {
                    try {
                      final int? templateId = component.template?.id;

                      if (templateId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu này chưa có !'),
                          ),
                        );
                        return;
                      }

                      final template = await TemplateService.fetchTemplateById(
                        templateId,
                      );

                      if (template.printFileBase64.isEmpty) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu chưa có file'),
                          ),
                        );
                        return;
                      }

                      if (template.isPdf) {
                        final pdfFile = await createPdfFromBase64(
                          template.printFileBase64,
                        );

                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PdfViewerScreen(filePath: pdfFile.path),
                          ),
                        );
                      } else {
                        await FileHelper.openFile(
                          base64: template.printFileBase64,
                          filename: template.printFilename,
                        );
                      }
                    } catch (e) {
                      debugPrint(e.toString());

                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể mở biểu mẫu')),
                      );
                    }
                  },

                  onPrint: () async {
                    try {
                      final int? templateId = component.template?.id;

                      if (templateId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Không có biểu mẫu để in'),
                          ),
                        );
                        return;
                      }

                      final template = await TemplateService.fetchTemplateById(
                        templateId,
                      );

                      if (template.printFileBase64.isEmpty) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Biểu mẫu chưa có file'),
                          ),
                        );
                        return;
                      }

                      if (!template.isPdf) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Chỉ hỗ trợ in trực tiếp file PDF.'),
                          ),
                        );
                        return;
                      }

                      final pdfBytes = base64Decode(template.printFileBase64);

                      await Printing.layoutPdf(
                        onLayout: (_) async => pdfBytes,
                        name: template.printFilename.isNotEmpty
                            ? template.printFilename
                            : 'bieu_mau.pdf',
                      );
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Không thể in biểu mẫu')),
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 30),

            Text(
              "Cơ sở pháp lý",
              style: Theme.of(context).textTheme.titleLarge,
            ),

            ...detail.legalGrounds.map(
              (e) => ListTile(
                title: Text(e.referenceNumber),
                subtitle: Text(e.summary),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class FormRow extends StatelessWidget {
  final String label;
  final String value;

  const FormRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    // 🔥 tăng mạnh font
    final double labelFontSize = screenW >= 1400
        ? 20
        : screenW >= 1000
        ? 18
        : 16;

    final double valueFontSize = screenW >= 1400
        ? 20
        : screenW >= 1000
        ? 17
        : 15;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: screenW >= 1400 ? 240 : 200,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: labelFontSize,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                color: Colors.black87,
                fontSize: valueFontSize,
                height: 1.6, // 🔥 dễ đọc hơn
              ),
            ),
          ),
        ],
      ),
    );
  }
}
