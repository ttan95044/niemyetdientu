import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';
import 'package:niemyetdientu/widgets/pdf_editor_overlay.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:niemyetdientu/service/log_service.dart';
import 'package:niemyetdientu/service/resolution_helper.dart';
import 'package:path_provider/path_provider.dart';

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

  /// 📄 Working PDF file path - persisted locally during editing
  /// Updated after each text add/drag operation
  late String _workingPdfPath;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _initializeWorkingPdf();
  }

  /// 📄 Initialize working PDF by copying source to app-local storage
  /// Uses getApplicationDocumentsDirectory() - no permission issues
  Future<void> _initializeWorkingPdf() async {
    try {
      // Use app-specific documents directory (no external permissions needed)
      final appDocsDir = await getApplicationDocumentsDirectory();
      debugPrint('📍 Using app documents dir: ${appDocsDir.path}');

      final previewDir = Directory('${appDocsDir.path}/pdf_preview');

      // Create pdf_preview folder if not exists
      if (!await previewDir.exists()) {
        await previewDir.create(recursive: true);
      }

      _workingPdfPath = '${previewDir.path}/bieu_mau_working.pdf';

      // Copy source PDF to working path
      final sourceFile = File(widget.filePath);
      if (await sourceFile.exists()) {
        await sourceFile.copy(_workingPdfPath);
        LogService.send({
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
          'action': 'working_pdf_initialized',
          'working_pdf_path': _workingPdfPath,
        });
      }
    } catch (e) {
      LogService.send({
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'action': 'working_pdf_init_error',
        'error_message': e.toString(),
      });
    }
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
                      onTextPositionChanged: (item, newX, newY, newPageIndex) {
                        LogService.send({
                          'Timestamp': DateTime.now().toUtc().toIso8601String(),
                          'action': 'text_position_changed',
                          'item_id': item.id,
                          'item_text': item.text,
                          'new_x': newX.toStringAsFixed(2),
                          'new_y': newY.toStringAsFixed(2),
                          'page_index': newPageIndex,
                          'font_size': item.fontSize,
                        });

                        setState(() {
                          final index = textItems.indexWhere(
                            (t) => t.id == item.id,
                          );
                          if (index != -1) {
                            final oldItem = textItems[index];
                            // Update with full item which has new text/fontSize from edit modal
                            // and new position from drag/drop (x, y, pageIndex)
                            final updatedItem = PdfTextItem(
                              id: item.id,
                              text: item.text,
                              x: newX,
                              y: newY,
                              fontSize: item.fontSize,
                              fontColor: item.fontColor,
                              fontFamily: item.fontFamily,
                              pageIndex: newPageIndex,
                            );
                            textItems[index] = updatedItem;

                            LogService.send({
                              'Timestamp': DateTime.now()
                                  .toUtc()
                                  .toIso8601String(),
                              'action': 'text_item_updated',
                              'item_id': item.id,
                              'old_text': oldItem.text,
                              'old_font_size': oldItem.fontSize,
                              'new_text': updatedItem.text,
                              'new_font_size': updatedItem.fontSize,
                              'new_x': newX.toStringAsFixed(2),
                              'new_y': newY.toStringAsFixed(2),
                            });
                          }
                        });

                        /// 💾 Update working PDF after text edit/drag-drop
                        _updateWorkingPdf().then((_) {
                          LogService.send({
                            'Timestamp': DateTime.now()
                                .toUtc()
                                .toIso8601String(),
                            'action': 'pdf_update_after_position_change',
                            'item_id': item.id,
                            'item_text': item.text,
                          });
                        });
                      },
                      onTextDeleted: (item) {
                        setState(() {
                          textItems.removeWhere((t) => t.id == item.id);
                          selectedItem = null;
                        });

                        /// 💾 Update working PDF after delete
                        _updateWorkingPdf();
                      },
                      onTapToAdd: (pdfX, pdfY) {
                        _showAddTextModalAtPosition(pdfX, pdfY);
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
          title: const Text('Thêm nội dung mới'),
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

                  /// 💾 Update working PDF after adding text
                  _updateWorkingPdf();

                  Navigator.pop(dialogContext);
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content: Text('✅ Đã thêm text. Kéo thả để di chuyển'),
                  //   ),
                  // );
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

  /// Hiển thị modal để thêm text tại vị trí được chạm
  Future<void> _showAddTextModalAtPosition(double pdfX, double pdfY) {
    final textController = TextEditingController();
    final fontSizeController = TextEditingController(text: '16');

    return showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm nội dung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  maxLines: 3,
                  autofocus: true,
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

                  /// Calculate page index từ X coordinate (pages side-by-side)
                  const a4PageWidth = 595.28;
                  final calculatedPageIndex = (pdfX / a4PageWidth).floor();
                  final normalizedX =
                      pdfX - (calculatedPageIndex * a4PageWidth);

                  final newItem = PdfTextItem(
                    id: 'text_${nextTextId++}',
                    text: textController.text,
                    x: normalizedX,
                    y: pdfY,
                    fontSize: newFontSize,
                    pageIndex: calculatedPageIndex,
                  );

                  setState(() {
                    textItems.add(newItem);
                    selectedItem = newItem;
                  });

                  /// 💾 Update working PDF after adding text
                  _updateWorkingPdf();

                  Navigator.pop(dialogContext);

                  /// Log vị trí text được thêm
                  LogService.send({
                    'Message':
                        'Text added by tap at (${normalizedX.toStringAsFixed(2)}, ${pdfY.toStringAsFixed(2)}) on page $calculatedPageIndex: "${textController.text}"',
                    'Timestamp': DateTime.now().toUtc().toIso8601String(),
                    'action': 'text_added_by_tap',
                    'position': {
                      'x': normalizedX.toStringAsFixed(2),
                      'y': pdfY.toStringAsFixed(2),
                      'pageIndex': calculatedPageIndex,
                    },
                    'text': textController.text,
                    'fontSize': newFontSize,
                    'endpoint': 'editor/text-added',
                  });

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

  /// 💾 Update working PDF file after text changes (add/drag)
  /// Renders PDF with current textItems, saves to working path
  Future<void> _updateWorkingPdf() async {
    if (textItems.isEmpty) {
      debugPrint('⚠️ No text items, keeping original PDF');
      return;
    }

    try {
      /// Group items by page for summary
      final Map<int, List<PdfTextItem>> itemsByPage = {};
      for (var item in textItems) {
        itemsByPage.putIfAbsent(item.pageIndex, () => []).add(item);
      }

      /// Log PDF update session start with item summary
      LogService.send({
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'action': 'pdf_update_started',
        'total_text_items': textItems.length,
        'pages_with_items': itemsByPage.keys.length,
        'items_per_page': itemsByPage.map(
          (k, v) => MapEntry(k.toString(), v.length),
        ),
      });

      debugPrint('🔄 _updateWorkingPdf() - Rendering...');
      final pdf = pw.Document();

      /// Load NotoSans font for Vietnamese support
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final font = pw.Font.ttf(fontData);

      /// Get page count from original PDF
      final sourceFile = File(widget.filePath);
      if (!await sourceFile.exists()) {
        debugPrint('❌ Source PDF not found');
        return;
      }

      final sourceBytes = await sourceFile.readAsBytes();
      final document = await pdfx.PdfDocument.openData(sourceBytes);
      final pageCount = document.pagesCount;

      /// Render all pages
      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        try {
          // 🔧 FIX: Calculate exact A4-fit size BEFORE rendering image
          // This ensures image + text scales are perfectly aligned
          const pdfWidth = 612.0;
          const pdfHeight = 792.0;
          final a4Width = PdfPageFormat.a4.width;
          final a4Height = PdfPageFormat.a4.height;

          final scaleX = a4Width / pdfWidth; // 0.9727
          final scaleY = a4Height / pdfHeight; // 1.0631
          final scale = (scaleX < scaleY) ? scaleX : scaleY; // 0.9727

          final scaledPdfWidth = pdfWidth * scale; // 595.27
          final scaledPdfHeight = pdfHeight * scale; // 769.93

          // ✅ Render image with EXACT target size to match text scale
          // Previously rendered at 1200x1552, then scaled down (mismatch!)
          // Now render at scaled size directly (no scale mismatch)
          final renderWidth = scaledPdfWidth * 2; // 2x for quality (as double)
          final renderHeight = scaledPdfHeight * 2;

          final pdfPage = await document.getPage(pageIndex + 1);
          final pageImage = await pdfPage.render(
            width: renderWidth,
            height: renderHeight,
          );

          if (pageImage == null) {
            throw Exception('Render trang $pageIndex trả về null');
          }

          final pwImage = pw.MemoryImage(pageImage.bytes);

          /// Add page with image + text overlay
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                // 🔧 FIX: Use NATIVE PDF coordinates (612x792) consistently
                // Render image at native size, text at native coordinates
                // (no A4 scaling/centering offsets - those are cosmetic only)
                const pdfWidth = 612.0;
                const pdfHeight = 792.0;

                // Scale to fit A4 for final output
                const a4Width = 595.28;
                const a4Height = 841.89;

                final scaleToA4 = a4Width / pdfWidth; // 0.9727

                // Center the scaled image on A4
                final scaledWidth = pdfWidth * scaleToA4; // 595.27
                final scaledHeight = pdfHeight * scaleToA4; // 769.93
                final offsetX = (a4Width - scaledWidth) / 2; // 0.005
                final offsetY = (a4Height - scaledHeight) / 2; // 35.96

                return pw.Stack(
                  children: [
                    // Image positioned and scaled to A4
                    pw.Positioned(
                      left: offsetX,
                      top: offsetY,
                      child: pw.SizedBox(
                        width: scaledWidth,
                        height: scaledHeight,
                        child: pw.Image(pwImage),
                      ),
                    ),

                    /// Add text items for this page
                    /// Text coordinates are NATIVE PDF (612x792)
                    /// Only apply offsetX, NOT offsetY (image handles vertical centering)
                    ...textItems.where((item) => item.pageIndex == pageIndex).map((
                      item,
                    ) {
                      // Text in native PDF coordinates
                      // Scale from native (612x792) to A4-fit size
                      final scaledX = item.x * scaleToA4;
                      final scaledY = item.y * scaleToA4;

                      // Get resolution-specific offset corrections
                      final resolutionHelper = ResolutionHelper();
                      final offsets = resolutionHelper.getOffsetCorrections();
                      final renderOffsetX = offsets['offsetX']!;
                      final renderOffsetY = offsets['offsetY']!;

                      // Position on A4 - apply offsets with adjustment factor
                      // offsetY needs partial application due to coordinate system differences
                      final finalX =
                          scaledX +
                          offsetX +
                          renderOffsetX; // Apply resolution-specific offset
                      final finalY =
                          scaledY +
                          (offsetY * 0.55) +
                          renderOffsetY; // Apply resolution-specific offset
                      final scaledFontSize = item.fontSize * scaleToA4;

                      /// Log render - single consolidated entry
                      LogService.send({
                        'Timestamp': DateTime.now().toUtc().toIso8601String(),
                        'action': 'text_rendered',
                        'item_id': item.id,
                        'item_text': item.text,
                        'page_index': item.pageIndex,
                        'device_profile': resolutionHelper.getDeviceProfile(),
                        'native_pdf_x': item.x.toStringAsFixed(2),
                        'native_pdf_y': item.y.toStringAsFixed(2),
                        'scale_to_a4': scaleToA4.toStringAsFixed(6),
                        'scaled_x': scaledX.toStringAsFixed(2),
                        'scaled_y': scaledY.toStringAsFixed(2),
                        'a4_offset_x': offsetX.toStringAsFixed(2),
                        'a4_offset_y_adjusted': (offsetY * 0.55)
                            .toStringAsFixed(2),
                        'device_offset_x': renderOffsetX.toStringAsFixed(2),
                        'device_offset_y': renderOffsetY.toStringAsFixed(2),
                        'final_x': finalX.toStringAsFixed(2),
                        'final_y': finalY.toStringAsFixed(2),
                        'final_font_size': scaledFontSize.toStringAsFixed(2),
                      });

                      return pw.Positioned(
                        left: finalX,
                        top: finalY,
                        child: pw.Text(
                          item.text,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: scaledFontSize,
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
          /// Fallback blank page if render fails
          final itemsOnPage = textItems
              .where((item) => item.pageIndex == pageIndex)
              .toList();

          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                // 🔧 FIX: Use NATIVE PDF coordinates consistently
                const pdfWidth = 612.0;
                const pdfHeight = 792.0;
                const a4Width = 595.28;
                const a4Height = 841.89;

                final scaleToA4 = a4Width / pdfWidth; // 0.9727

                final scaledWidth = pdfWidth * scaleToA4;
                final scaledHeight = pdfHeight * scaleToA4;
                // Center on A4
                final offsetX = (a4Width - scaledWidth) / 2;
                final offsetY = (a4Height - scaledHeight) / 2;

                return pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.Container(color: PdfColors.white),
                    ),
                    ...itemsOnPage.map((item) {
                      /// Scale and position text using native PDF coordinates
                      final scaledX = item.x * scaleToA4;
                      final scaledY = item.y * scaleToA4;

                      // Get resolution-specific offset corrections
                      final resolutionHelper = ResolutionHelper();
                      final offsets = resolutionHelper.getOffsetCorrections();
                      final renderOffsetX = offsets['offsetX']!;
                      final renderOffsetY = offsets['offsetY']!;

                      // Adjustment: apply resolution-specific offsets
                      final finalX =
                          scaledX +
                          offsetX +
                          renderOffsetX; // Apply resolution-specific offset
                      final finalY =
                          scaledY +
                          (offsetY * 0.55) +
                          renderOffsetY; // Apply resolution-specific offset

                      /// Log fallback render - single consolidated entry
                      LogService.send({
                        'Timestamp': DateTime.now().toUtc().toIso8601String(),
                        'action': 'text_rendered_fallback',
                        'item_id': item.id,
                        'item_text': item.text,
                        'page_index': item.pageIndex,
                        'device_profile': resolutionHelper.getDeviceProfile(),
                        'native_pdf_x': item.x.toStringAsFixed(2),
                        'native_pdf_y': item.y.toStringAsFixed(2),
                        'scale_to_a4': scaleToA4.toStringAsFixed(6),
                        'scaled_x': scaledX.toStringAsFixed(2),
                        'scaled_y': scaledY.toStringAsFixed(2),
                        'final_x': finalX.toStringAsFixed(2),
                        'final_y': finalY.toStringAsFixed(2),
                      });

                      // 📊 Log render coordinates for debugging (fallback path)
                      return pw.Positioned(
                        left: finalX,
                        top: finalY,
                        child: pw.Text(
                          item.text,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: item.fontSize * scaleToA4,
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

      /// Save to working path
      final pdfBytes = await pdf.save();
      final workingFile = File(_workingPdfPath);
      await workingFile.writeAsBytes(pdfBytes);

      /// Log PDF update completed
      LogService.send({
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'action': 'pdf_update_completed',
        'total_items_rendered': textItems.length,
        'pages_updated': textItems.map((item) => item.pageIndex).toSet().length,
        'output_size_bytes': pdfBytes.length,
        'output_size_kb': (pdfBytes.length / 1024).toStringAsFixed(2),
      });
    } catch (e, st) {
      LogService.send({
        'Message': '❌ Error updating working PDF: $e\n$st',
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  /// 🖨️ Print working PDF file
  /// Loads persisted PDF with all text changes and previews for printing
  Future<void> _printEditedPdf() async {
    try {
      // 📊 Log current state before printing
      LogService.send({
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'action': 'print_started',
        'total_items': textItems.length,
        'items': textItems.map((t) => t.text).toList(),
      });

      debugPrint('═══════════════════════════════════════');
      debugPrint('🔵 _printEditedPdf() START');
      debugPrint('📊 Using working PDF: $_workingPdfPath');
      debugPrint('═══════════════════════════════════════');

      /// Load working PDF
      final workingFile = File(_workingPdfPath);
      if (!await workingFile.exists()) {
        LogService.send({
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
          'action': 'print_working_pdf_not_found',
          'working_pdf_path': _workingPdfPath,
          'fallback_to': 'original',
        });
        debugPrint('⚠️ Working PDF not found, using original');
        final originalFile = File(widget.filePath);
        final pdfBytes = await originalFile.readAsBytes();

        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'bieu_mau.pdf',
        );
      } else {
        final pdfBytes = await workingFile.readAsBytes();
        debugPrint('📊 Read bytes: ${pdfBytes.length} bytes');

        LogService.send({
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
          'action': 'print_working_pdf_loaded',
          'file_size_bytes': pdfBytes.length,
          'file_path': _workingPdfPath,
        });

        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'bieu_mau_edited.pdf',
        );

        debugPrint('✅ PDF sent to print');

        LogService.send({
          'Timestamp': DateTime.now().toUtc().toIso8601String(),
          'action': 'print_sent_to_preview',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Đã gửi tới in')));
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR: $e');
      debugPrint('📍 StackTrace:\n$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Lỗi in: $e')));
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
