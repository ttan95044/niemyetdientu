// import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';
import 'package:niemyetdientu/widgets/pdf_editor_overlay.dart';
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

  /// Thanh công cụ chứa nút thêm text và hiển thị số lượng
  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Row(
        children: [
          /// Nút thêm text mới
          ElevatedButton.icon(
            onPressed: _showAddTextModal,
            icon: const Icon(Icons.add),
            label: const Text('Thêm text'),
          ),

          /// Hiển thị số text được thêm
          const SizedBox(width: 12),
          Tooltip(
            message: 'Số text được thêm',
            child: Chip(
              label: Text('${textItems.length} text'),
              backgroundColor: Colors.blue,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ),

          const Spacer(),
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
            child: Center(
              child: AspectRatio(
                aspectRatio: 612 / 792, // PDF aspect ratio
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
                      zoomLevel: zoomLevel,
                      transformationMatrix: _transformationController.value,
                      selectedItem: selectedItem,
                      onTextSelected: (item) {
                        setState(() {
                          selectedItem = item.id.isEmpty ? null : item;
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
                      onTextDeleted: (item) {
                        setState(() {
                          textItems.removeWhere((t) => t.id == item.id);
                          selectedItem = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
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

  /// Hiển thị modal để thêm text mới
  Future<void> _showAddTextModal() {
    final textController = TextEditingController();
    final fontSizeController = TextEditingController(text: '16');

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm text mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Text content
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Nội dung',
                    hintText: 'Nhập nội dung text...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),

                /// Font size
                TextField(
                  controller: fontSizeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kích thước (pt)',
                    hintText: '16',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('❌ Vui lòng nhập nội dung')),
                  );
                  return;
                }

                try {
                  final newFontSize = double.parse(
                    fontSizeController.text.isNotEmpty
                        ? fontSizeController.text
                        : '16',
                  ).clamp(2.0, 72.0);

                  final newItem = PdfTextItem(
                    id: 'text_${nextTextId++}',
                    text: textController.text,
                    x: 50,
                    y: 50,
                    fontSize: newFontSize,
                  );

                  setState(() {
                    textItems.add(newItem);
                    selectedItem = newItem;
                  });

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Đã thêm text. Kéo thả để di chuyển'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('❌ Kích thước không hợp lệ')),
                  );
                }
              },
              child: const Text('Thêm'),
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

      /// 📐 Log A4 page dimensions
      const pdfWidth = 612.0;
      const pdfHeight = 792.0;
      final a4Width = PdfPageFormat.a4.width;
      final a4Height = PdfPageFormat.a4.height;
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📄 PREVIEW PAGE SIZE (A4):');
      debugPrint('   → Width: ${a4Width.toStringAsFixed(2)} pt');
      debugPrint('   → Height: ${a4Height.toStringAsFixed(2)} pt');
      debugPrint(
        '   → Aspect ratio: ${(a4Width / a4Height).toStringAsFixed(4)}',
      );
      debugPrint(
        '📄 PDF Original: ${pdfWidth.toStringAsFixed(2)}×${pdfHeight.toStringAsFixed(2)} pt',
      );
      debugPrint(
        '   → Aspect ratio: ${(pdfWidth / pdfHeight).toStringAsFixed(4)}',
      );
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');

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

            /// Render trang thành image, maintaining PDF aspect ratio (612:792)
            /// Render dimensions: 1200 x 1552 (maintains 612:792 ratio exactly for accurate positioning)
            final pageImage = await pdfPage.render(width: 1200, height: 1552);

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
                  // PDF original dimensions
                  const pdfWidth = 612.0;
                  const pdfHeight = 792.0;

                  final a4Width = PdfPageFormat.a4.width;
                  final a4Height = PdfPageFormat.a4.height;

                  /// Scale PDF to fit within A4 maintaining PDF aspect ratio
                  final scaleX = a4Width / pdfWidth; // 0.9727
                  final scaleY = a4Height / pdfHeight; // 1.0631
                  final scale = (scaleX < scaleY)
                      ? scaleX
                      : scaleY; // Use min = 0.9727

                  /// Calculate centering offset based on scaled PDF
                  final scaledPdfWidth = pdfWidth * scale;
                  final scaledPdfHeight = pdfHeight * scale;
                  final offsetX = (a4Width - scaledPdfWidth) / 2;
                  // For offsetY: don't add full centering offset for text
                  // Use half the offset to account for proper text alignment
                  final offsetY = (a4Height - scaledPdfHeight) / 2 * 0.5;

                  return pw.Stack(
                    children: [
                      /// Nhúng image của trang PDF gốc với positioning cụ thể
                      /// Định vị tại offset tính toán từ PDF scaling
                      pw.Positioned(
                        left: offsetX,
                        top: offsetY,
                        child: pw.SizedBox(
                          width: scaledPdfWidth,
                          height: scaledPdfHeight,
                          child: pw.Image(pwImage),
                        ),
                      ),

                      /// Text overlay - chèn các text item (chỉ hiện trên trang 1)
                      /// Dùng cùng scale và offset với image
                      if (pageIndex == 0)
                        ...textItems.map((item) {
                          /// Final position: scale PDF coords then add offset
                          final finalX = item.x * scale + offsetX;
                          final finalY = item.y * scale + offsetY;

                          /// Font scaling
                          final scaleFontSize = scale;

                          /// 📐 DEBUG: Log positioning details
                          debugPrint('');
                          debugPrint(
                            '📋 MAIN PDF TEXT: "${item.text}" (ID: ${item.id})',
                          );
                          debugPrint(
                            '  PDF SPACE: x=${item.x.toStringAsFixed(2)}, y=${item.y.toStringAsFixed(2)}',
                          );
                          debugPrint(
                            '  Scale PDF→A4: ${scale.toStringAsFixed(4)} (min of X=${scaleX.toStringAsFixed(4)}, Y=${scaleY.toStringAsFixed(4)})',
                          );
                          debugPrint(
                            '  Centering offset: X=${offsetX.toStringAsFixed(2)}, Y=${offsetY.toStringAsFixed(2)}',
                          );
                          debugPrint('  Final A4 position with offset:');
                          debugPrint(
                            '    finalX=${finalX.toStringAsFixed(2)}, finalY=${finalY.toStringAsFixed(2)}',
                          );
                          debugPrint(
                            '    fontSize=${item.fontSize} * ${scaleFontSize.toStringAsFixed(4)} = ${(item.fontSize * scaleFontSize).toStringAsFixed(2)}',
                          );

                          return pw.Positioned(
                            left: finalX,
                            top: finalY,
                            child: pw.Text(
                              item.text,
                              style: pw.TextStyle(
                                fontSize: item.fontSize * scaleFontSize,
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
                          const pdfWidth = 612.0;
                          const pdfHeight = 792.0;
                          final a4Width = PdfPageFormat.a4.width; // 595.28
                          final a4Height = PdfPageFormat.a4.height; // 841.89

                          /// Scale PDF to fit within A4 maintaining PDF aspect ratio
                          final scaleX = a4Width / pdfWidth;
                          final scaleY = a4Height / pdfHeight;
                          final scale = (scaleX < scaleY) ? scaleX : scaleY;

                          final scaledPdfWidth = pdfWidth * scale;
                          final scaledPdfHeight = pdfHeight * scale;
                          final offsetX = (a4Width - scaledPdfWidth) / 2;
                          final offsetY = (a4Height - scaledPdfHeight) / 2;

                          final finalX = item.x * scale + offsetX;
                          final finalY = item.y * scale + offsetY;
                          final scaleFontSize = scale;

                          /// 📐 DEBUG: Log (fallback 1)
                          debugPrint('');
                          debugPrint('📋 FALLBACK1 TEXT: "${item.text}"');
                          debugPrint(
                            '  PDF: x=${item.x.toStringAsFixed(2)}, y=${item.y.toStringAsFixed(2)}',
                          );
                          debugPrint(
                            '  Scale: ${scale.toStringAsFixed(4)}, Offset: (${offsetX.toStringAsFixed(2)}, ${offsetY.toStringAsFixed(2)})',
                          );
                          debugPrint(
                            '  A4 final: x=${finalX.toStringAsFixed(2)}, y=${finalY.toStringAsFixed(2)}',
                          );

                          return pw.Positioned(
                            left: finalX,
                            top: finalY,
                            child: pw.Text(
                              item.text,
                              style: pw.TextStyle(
                                fontSize: item.fontSize * scaleFontSize,
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
                    const pdfWidth = 612.0;
                    const pdfHeight = 792.0;
                    final a4Width = PdfPageFormat.a4.width;
                    final a4Height = PdfPageFormat.a4.height;

                    /// Scale PDF to fit within A4 maintaining PDF aspect ratio
                    final scaleX = a4Width / pdfWidth;
                    final scaleY = a4Height / pdfHeight;
                    final scale = (scaleX < scaleY) ? scaleX : scaleY;

                    final scaledPdfWidth = pdfWidth * scale;
                    final scaledPdfHeight = pdfHeight * scale;
                    final offsetX = (a4Width - scaledPdfWidth) / 2;
                    final offsetY = (a4Height - scaledPdfHeight) / 2;

                    final finalX = item.x * scale + offsetX;
                    final finalY = item.y * scale + offsetY;
                    final scaleFontSize = scale;

                    /// 📐 DEBUG: Log (fallback 2 - white bg)
                    debugPrint('');
                    debugPrint('📋 FALLBACK2 (WHITE) TEXT: "${item.text}"');
                    debugPrint(
                      '  PDF: x=${item.x.toStringAsFixed(2)}, y=${item.y.toStringAsFixed(2)}',
                    );
                    debugPrint(
                      '  Scale: ${scale.toStringAsFixed(4)}, Offset: (${offsetX.toStringAsFixed(2)}, ${offsetY.toStringAsFixed(2)})',
                    );
                    debugPrint(
                      '  A4 final: x=${finalX.toStringAsFixed(2)}, y=${finalY.toStringAsFixed(2)}',
                    );

                    return pw.Positioned(
                      left: finalX,
                      top: finalY,
                      child: pw.Text(
                        item.text,
                        style: pw.TextStyle(
                          fontSize: item.fontSize * scaleFontSize,
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
