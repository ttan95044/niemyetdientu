// import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';
import 'package:niemyetdientu/widgets/pdf_editor_overlay.dart';
import 'package:niemyetdientu/widgets/edit_text_form.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  /// Danh sách các text item được thêm vào
  final List<PdfTextItem> textItems = [];

  /// ID tiếp theo để tạo từ
  int nextTextId = 0;

  /// Text hiện tại đang được chỉnh sửa
  PdfTextItem? selectedItem;

  /// Zoom level (1.0 = 100%)
  double zoomLevel = 1.0;
  final double minZoom = 0.5;
  final double maxZoom = 3.0;
  final double zoomStep = 0.25;

  /// TransformationController cho InteractiveViewer
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa biểu mẫu'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          /// Nút in PDF
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Tooltip(
                message: 'In PDF với nội dung đã chỉnh sửa',
                child: TextButton.icon(
                  onPressed: _printEditedPdf,
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text(
                    'In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// ===== Thanh công cụ để chỉnh sửa =====
          _buildToolbar(),

          /// ===== PDF Viewer với Text Overlay =====
          Expanded(child: _buildPdfEditorArea()),
        ],
      ),
    );
  }

  /// Thanh công cụ chứa input field và nút chỉnh sửa
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          /// Input field để nhập text
          Expanded(child: EditTextForm(onAddText: _onAddTextItem)),

          /// Nút xóa text được chọn
          if (selectedItem != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Xóa text',
              child: IconButton(
                onPressed: _deleteSelectedText,
                icon: const Icon(Icons.delete),
                color: Colors.red,
              ),
            ),
          ],

          /// Nút chi tiết chỉnh sửa text được chọn
          if (selectedItem != null) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Chỉnh sửa text',
              child: IconButton(
                onPressed: () => _showEditTextDialog(selectedItem!),
                icon: const Icon(Icons.edit),
              ),
            ),
          ],

          /// Hiển thị số text được thêm
          const SizedBox(width: 8),
          Tooltip(
            message: 'Số text được thêm',
            child: Chip(
              label: Text('${textItems.length} text'),
              backgroundColor: Colors.blue,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Khu vực PDF với overlay text
  Widget _buildPdfEditorArea() {
    return Column(
      children: [
        /// Zoom controls
        _buildZoomControls(),

        /// PDF Viewer với zoom support (pinch-to-zoom, pan)
        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: minZoom,
            maxScale: maxZoom,
            boundaryMargin: const EdgeInsets.all(20),
            onInteractionEnd: (details) {
              /// Cập nhật zoom level khi user zoom bằng pinch hoặc button
              setState(() {
                zoomLevel = _transformationController.value.getMaxScaleOnAxis();
                zoomLevel = zoomLevel.clamp(minZoom, maxZoom);
              });
            },
            child: Stack(
              children: [
                /// PDF Viewer
                PDFView(
                  filePath: widget.filePath,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                ),

                /// Text Overlay trên PDF
                PdfEditorOverlay(
                  textItems: textItems,
                  zoomLevel: 1.0,
                  transformationMatrix: _transformationController.value,
                  selectedItem: selectedItem,
                  onTextSelected: (item) {
                    setState(() {
                      selectedItem = item;
                    });
                  },
                  onTextPositionChanged: (item, newX, newY) {
                    setState(() {
                      final index = textItems.indexWhere(
                        (t) => t.id == item.id,
                      );
                      if (index != -1) {
                        textItems[index] = item.copyWith(x: newX, y: newY);
                      }
                    });
                  },
                  onTextSizeChanged: (item, newSize) {
                    setState(() {
                      final index = textItems.indexWhere(
                        (t) => t.id == item.id,
                      );
                      if (index != -1) {
                        textItems[index] = item.copyWith(fontSize: newSize);
                        selectedItem = textItems[index];
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Zoom control buttons
  Widget _buildZoomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          /// Nút zoom out
          Tooltip(
            message: 'Thu nhỏ',
            child: IconButton(
              onPressed: _zoomOut,
              icon: const Icon(Icons.zoom_out),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),

          /// Hiển thị zoom level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(zoomLevel * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          /// Nút zoom in
          Tooltip(
            message: 'Phóng to',
            child: IconButton(
              onPressed: _zoomIn,
              icon: const Icon(Icons.zoom_in),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),

          /// Nút reset zoom
          Tooltip(
            message: 'Reset zoom',
            child: TextButton.icon(
              onPressed: _resetZoom,
              icon: const Icon(Icons.fit_screen),
              label: const Text('Fit'),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  /// Zoom in
  void _zoomIn() {
    setState(() {
      zoomLevel = (zoomLevel + zoomStep).clamp(minZoom, maxZoom);
      _updateTransformationMatrix();
    });
  }

  /// Zoom out
  void _zoomOut() {
    setState(() {
      zoomLevel = (zoomLevel - zoomStep).clamp(minZoom, maxZoom);
      _updateTransformationMatrix();
    });
  }

  /// Reset zoom to fit
  void _resetZoom() {
    setState(() {
      zoomLevel = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  /// Cập nhật transformation matrix theo zoom level
  void _updateTransformationMatrix() {
    _transformationController.value = Matrix4.identity()..scale(zoomLevel);
  }

  /// Thêm text item mới
  void _onAddTextItem(String text) {
    if (text.trim().isEmpty) return;

    final newItem = PdfTextItem(
      id: 'text_${nextTextId++}',
      text: text,
      x: 50, // Vị trí mặc định
      y: 50,
    );

    setState(() {
      textItems.add(newItem);
      selectedItem = newItem;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã thêm text. Kéo thả để di chuyển vị trí'),
      ),
    );
  }

  /// Xóa text được chọn
  void _deleteSelectedText() {
    if (selectedItem == null) return;

    setState(() {
      textItems.removeWhere((t) => t.id == selectedItem!.id);
      selectedItem = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🗑️ Đã xóa text')));
  }

  /// Hiển thị dialog chỉnh sửa text
  Future<void> _showEditTextDialog(PdfTextItem item) {
    final textController = TextEditingController(text: item.text);
    final fontSizeController = TextEditingController(
      text: item.fontSize.toString(),
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chỉnh sửa text'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Input text
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                /// Font size
                TextField(
                  controller: fontSizeController,
                  decoration: const InputDecoration(
                    labelText: 'Kích thước chữ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final newFontSize =
                    double.tryParse(fontSizeController.text) ?? item.fontSize;
                setState(() {
                  final index = textItems.indexWhere((t) => t.id == item.id);
                  if (index != -1) {
                    textItems[index] = item.copyWith(
                      text: textController.text,
                      fontSize: newFontSize,
                    );
                    selectedItem = textItems[index];
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  /// In PDF với nội dung đã chỉnh sửa
  /// Render PDF gốc thành image + overlay text
  /// Hỗ trợ in trên Windows, macOS, Android, iOS
  Future<void> _printEditedPdf() async {
    try {
      debugPrint('🖨️ Bắt đầu in PDF...');

      /// Nếu không có text được thêm, in PDF gốc
      if (textItems.isEmpty) {
        debugPrint('📄 Không có text được thêm, in PDF gốc');
        final pdfFile = File(widget.filePath);
        final pdfBytes = await pdfFile.readAsBytes();

        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'bieu_mau.pdf',
        );

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ Đã gửi tới in')));
        }
        return;
      }

      debugPrint(
        '📝 Có ${textItems.length} text được thêm, render PDF với overlay...',
      );

      /// Tạo document PDF mới
      final pdf = pw.Document();

      /// Cố gắng render PDF gốc + overlay text
      try {
        /// Mở PDF gốc
        final pdfFile = File(widget.filePath);
        if (!pdfFile.existsSync()) {
          throw Exception('File PDF không tồn tại: ${widget.filePath}');
        }

        final document = await pdfx.PdfDocument.openFile(widget.filePath);
        final pageCount = document.pagesCount;
        debugPrint('📄 PDF có $pageCount trang');

        /// Render từng trang
        for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
          try {
            final pageNum = pageIndex + 1;
            debugPrint('🔄 Render trang $pageNum/$pageCount...');

            /// Lấy trang từ PDF gốc
            final pdfPage = await document.getPage(pageIndex + 1);

            /// Render trang thành image
            final pageImage = await pdfPage.render(width: 1920, height: 1920);

            if (pageImage == null) {
              throw Exception('Render trang $pageNum trả về null');
            }

            /// Chuyển PdfPageImage sang bytes
            final pageImageBytes = pageImage.bytes;

            final pwImage = pw.MemoryImage(pageImageBytes);

            debugPrint('✅ Render trang $pageNum thành công');

            /// Tạo trang mới với image background
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: pw.EdgeInsets.zero,
                build: (pw.Context context) {
                  return pw.Stack(
                    children: [
                      /// Nhúng image của trang PDF gốc
                      pw.Positioned.fill(
                        child: pw.Image(pwImage, fit: pw.BoxFit.cover),
                      ),

                      /// Text overlay - chèn các text item (chỉ hiện trên trang 1)
                      if (pageIndex == 0)
                        ...textItems.map((item) {
                          return pw.Positioned(
                            left: item.x,
                            top: item.y,
                            child: pw.Text(
                              item.text,
                              style: pw.TextStyle(
                                fontSize: item.fontSize,
                                color: _parseColor(item.fontColor),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  );
                },
              ),
            );
          } catch (e) {
            debugPrint('⚠️ Lỗi render trang ${pageIndex + 1}: $e');

            /// Fallback: tạo trang trắng nếu render fail
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: pw.EdgeInsets.zero,
                build: (pw.Context context) {
                  return pw.Stack(
                    children: [
                      pw.Positioned.fill(
                        child: pw.Container(color: PdfColors.white),
                      ),
                      if (pageIndex == 0)
                        ...textItems.map((item) {
                          return pw.Positioned(
                            left: item.x,
                            top: item.y,
                            child: pw.Text(
                              item.text,
                              style: pw.TextStyle(
                                fontSize: item.fontSize,
                                color: _parseColor(item.fontColor),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  );
                },
              ),
            );
          }
        }
      } catch (e) {
        debugPrint(
          '⚠️ Không thể render PDF gốc, fallback sang white background: $e',
        );

        /// Fallback: Tạo 1 trang trắng với text
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Container(color: PdfColors.white),
                  ),
                  ...textItems.map((item) {
                    return pw.Positioned(
                      left: item.x,
                      top: item.y,
                      child: pw.Text(
                        item.text,
                        style: pw.TextStyle(
                          fontSize: item.fontSize,
                          color: _parseColor(item.fontColor),
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        );
      }

      /// In PDF
      debugPrint('📤 Gửi PDF tới in...');
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'bieu_mau_edited.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã gửi tới in thành công'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi in PDF: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Parse hex color string thành PdfColor
  PdfColor _parseColor(String hexColor) {
    try {
      // Loại bỏ ký tự '#' nếu có
      final color = hexColor.replaceFirst('#', '');
      final int colorInt = int.parse(color, radix: 16);
      final r = (colorInt >> 16) & 0xFF;
      final g = (colorInt >> 8) & 0xFF;
      final b = colorInt & 0xFF;
      return PdfColor(r / 255, g / 255, b / 255);
    } catch (e) {
      return PdfColors.black;
    }
  }
}
