import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';
import 'package:niemyetdientu/service/log_service.dart';
import 'package:niemyetdientu/service/resolution_helper.dart';

class PdfEditorOverlay extends StatefulWidget {
  final List<PdfTextItem> textItems;
  final Function(PdfTextItem) onTextSelected;
  final Function(PdfTextItem, double, double, int) onTextPositionChanged;
  final Function(PdfTextItem)? onTextDeleted;
  final Function(double, double)? onTapToAdd;
  final double zoomLevel;
  final Matrix4? transformationMatrix;
  final PdfTextItem? selectedItem;
  final double pdfWidth;
  final double pdfHeight;

  const PdfEditorOverlay({
    super.key,
    required this.textItems,
    required this.onTextSelected,
    required this.onTextPositionChanged,
    this.onTextDeleted,
    this.onTapToAdd,
    this.zoomLevel = 1.0,
    this.transformationMatrix,
    this.selectedItem,
    this.pdfWidth = 612.0,
    this.pdfHeight = 792.0,
  });

  @override
  State<PdfEditorOverlay> createState() => _PdfEditorOverlayState();
}

class _PdfEditorOverlayState extends State<PdfEditorOverlay> {
  /// Để theo dõi vị trí khi drag
  PdfTextItem? draggedItem;

  /// Global key để lấy position của Stack
  final GlobalKey _stackKey = GlobalKey();

  /// Helper: Tính toán kích thước thực tế của PDF được rendered
  /// maintain aspect ratio PDF khi fit vào stack
  /// Returns: (renderedWidth, renderedHeight, offsetX, offsetY)
  (double, double, double, double) _calculateRenderedPdfSize(Size stackSize) {
    final pdfAspectRatio = widget.pdfWidth / widget.pdfHeight;
    final stackAspectRatio = stackSize.width / stackSize.height;

    double renderedWidth, renderedHeight, offsetX, offsetY;

    if (stackAspectRatio > pdfAspectRatio) {
      // Stack rộng hơn PDF → PDF fill height, có padding left/right
      renderedHeight = stackSize.height;
      renderedWidth = renderedHeight * pdfAspectRatio;
      offsetX = (stackSize.width - renderedWidth) / 2;
      offsetY = 0;
    } else {
      // Stack cao hơn PDF → PDF fill width, có padding top/bottom
      renderedWidth = stackSize.width;
      renderedHeight = renderedWidth / pdfAspectRatio;
      offsetX = 0;
      offsetY = (stackSize.height - renderedHeight) / 2;
    }

    return (renderedWidth, renderedHeight, offsetX, offsetY);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        /// Khu vực background để detect tap và update position từ drag
        GestureDetector(
          onTapDown: (TapDownDetails details) {
            /// Chuyển đổi từ global position sang local position trên Stack
            final stackRenderBox =
                _stackKey.currentContext?.findRenderObject() as RenderBox?;
            if (stackRenderBox != null) {
              final stackGlobalOffset = stackRenderBox.localToGlobal(
                Offset.zero,
              );
              final stackSize = stackRenderBox.size;

              /// Local coords của tap position (trên screen, pre-zoom)
              var localX = (details.globalPosition.dx - stackGlobalOffset.dx);
              var localY = (details.globalPosition.dy - stackGlobalOffset.dy);

              // Undo zoom effect từ InteractiveViewer
              localX = localX / widget.zoomLevel;
              localY = localY / widget.zoomLevel;

              /// 🔧 FIX: Convert SCREEN coordinates back to NATIVE PDF coordinates
              /// Must use same rendered size logic as drag handler
              const pdfWidth = 612.0;
              const pdfHeight = 792.0;

              // Calculate rendered PDF size and offsets
              final (
                renderedWidth,
                renderedHeight,
                renderedOffsetX,
                renderedOffsetY,
              ) = _calculateRenderedPdfSize(
                stackSize,
              );

              // Scale factors from rendered back to native
              final scaleX = renderedWidth / pdfWidth;
              final scaleY = renderedHeight / pdfHeight;

              // Calculate page index from screen X
              final calculatedPageIndex =
                  ((localX - renderedOffsetX) / renderedWidth).floor().clamp(
                    0,
                    100,
                  );

              // Offset for current page
              final pageOffsetX = calculatedPageIndex * renderedWidth;

              // Get resolution-specific offset corrections
              final resolutionHelper = ResolutionHelper();
              final offsets = resolutionHelper.getOffsetCorrections();
              final offsetXCorrection = offsets['offsetX']!;
              final offsetYCorrection = offsets['offsetY']!;

              // Convert from screen pixels back to native PDF coordinates
              // IMPORTANT: Add back the rendering offsets so when PDF rendering
              // applies them again, the final position matches the visual tap position
              var pdfX =
                  ((localX - renderedOffsetX - pageOffsetX) / scaleX) +
                  offsetXCorrection; // Add back rendering offset
              var pdfY =
                  ((localY - renderedOffsetY) / scaleY) +
                  offsetYCorrection; // Add back rendering offset

              // Ensure within bounds (per-page)
              pdfX = pdfX.clamp(0.0, pdfWidth);
              pdfY = pdfY.clamp(0.0, pdfHeight);

              /// TAP-TO-ADD LOG - single consolidated log with all data
              final resProfile = resolutionHelper.getDeviceProfile();

              LogService.send({
                'Timestamp': DateTime.now().toUtc().toIso8601String(),
                'action': 'tap_to_add',
                'device_profile': resProfile,
                'screen_x': details.globalPosition.dx,
                'screen_y': details.globalPosition.dy,
                'local_x': localX.toStringAsFixed(2),
                'local_y': localY.toStringAsFixed(2),
                'zoom_level': widget.zoomLevel,
                'rendered_size':
                    '${renderedWidth.toStringAsFixed(0)}x${renderedHeight.toStringAsFixed(0)}',
                'scale_x': scaleX.toStringAsFixed(6),
                'scale_y': scaleY.toStringAsFixed(6),
                'page_index': calculatedPageIndex,
                'offset_x_correction': offsetXCorrection,
                'offset_y_correction': offsetYCorrection,
                'pdf_x_final': pdfX.toStringAsFixed(2),
                'pdf_y_final': pdfY.toStringAsFixed(2),
              });

              /// Gọi callback để thêm text tại vị trí được chạm
              widget.onTapToAdd?.call(pdfX, pdfY);
            }
          },
          child: Container(color: Colors.transparent),
        ),

        /// Danh sách text items với drag-drop
        ...widget.textItems.map((item) {
          return _buildDraggableTextItem(item);
        }).toList(),
      ],
    );
  }

  /// Tạo text item có thể kéo được
  Widget _buildDraggableTextItem(PdfTextItem item) {
    final isSelected = widget.selectedItem?.id == item.id;

    /// Convert từ PDF coordinates sang screen pixels (tại zoom = 1.0)
    /// InteractiveViewer sẽ handle zoom/pan transform

    // Get stack size
    final stackRenderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final stackSize = stackRenderBox?.size ?? const Size(600, 800);

    // 📐 Tính toán rendered PDF size (maintain aspect ratio)
    final (renderedWidth, renderedHeight, offsetX, offsetY) =
        _calculateRenderedPdfSize(stackSize);

    // Position tại zoom = 1.0 (before InteractiveViewer's matrix transform)
    // 🔧 FIX: Convert NATIVE PDF coordinates to SCREEN pixels
    // PDFView displays PDF at rendered size within stack
    // Must scale from native (612x792) to rendered dimensions

    const pdfWidth = 612.0;
    const pdfHeight = 792.0;

    // Scale factor from native PDF to rendered display
    final scaleX = renderedWidth / pdfWidth;
    final scaleY = renderedHeight / pdfHeight;

    /// Account for page index (side-by-side pages on TV)
    final pageOffsetX = item.pageIndex * renderedWidth;

    // Convert native PDF coords to screen pixels using rendered size
    final screenX = item.x * scaleX + offsetX + pageOffsetX;
    final screenY = item.y * scaleY + offsetY;

    return Positioned(
      left: screenX,
      top: screenY,
      child: Draggable<PdfTextItem>(
        data: item,
        feedback: _buildTextWidget(item, isSelected: true, isDragging: true),
        onDragStarted: () {
          /// Bắt đầu kéo
          draggedItem = item;
          widget.onTextSelected(item);
        },
        onDraggableCanceled: (velocity, offset) {
          /// Kết thúc kéo
          draggedItem = null;

          /// Cập nhật vị trí mới - convert global offset sang PDF coordinates
          final stackRenderBox =
              _stackKey.currentContext?.findRenderObject() as RenderBox?;
          if (stackRenderBox != null) {
            final stackGlobalOffset = stackRenderBox.localToGlobal(Offset.zero);
            final stackSize = stackRenderBox.size;

            /// Local coords của drag position (trên screen, pre-zoom)
            var localX = (offset.dx - stackGlobalOffset.dx);
            var localY = (offset.dy - stackGlobalOffset.dy);

            // Undo zoom effect từ InteractiveViewer
            localX = localX / widget.zoomLevel;
            localY = localY / widget.zoomLevel;

            // 🔧 FIX: Convert SCREEN coordinates back to NATIVE PDF coordinates
            // Must reverse the rendering scale and offsets
            const pdfWidth = 612.0;
            const pdfHeight = 792.0;

            // Calculate rendered PDF size and offsets
            final (
              renderedWidth,
              renderedHeight,
              renderedOffsetX,
              renderedOffsetY,
            ) = _calculateRenderedPdfSize(
              stackSize,
            );

            // Scale factors from rendered back to native
            final scaleX = renderedWidth / pdfWidth;
            final scaleY = renderedHeight / pdfHeight;

            // Calculate page index from screen X (pages side-by-side at rendered width)
            final calculatedPageIndex =
                ((localX - renderedOffsetX) / renderedWidth).floor().clamp(
                  0,
                  100,
                );

            // Offset for current page
            final pageOffsetX = calculatedPageIndex * renderedWidth;

            // Get resolution-specific offset corrections
            final resolutionHelper = ResolutionHelper();
            final offsets = resolutionHelper.getOffsetCorrections();
            final offsetXCorrection = offsets['offsetX']!;
            final offsetYCorrection = offsets['offsetY']!;

            // Convert from screen pixels back to native PDF coordinates
            // Reverse: screenX = item.x * scaleX + renderedOffsetX + pageOffsetX
            // IMPORTANT: Add back the rendering offsets so when PDF rendering
            // applies them again, the final position matches the visual drop position
            var pdfX =
                ((localX - renderedOffsetX - pageOffsetX) / scaleX) +
                offsetXCorrection; // Add back rendering offset
            var pdfY =
                ((localY - renderedOffsetY) / scaleY) +
                offsetYCorrection; // Add back rendering offset

            // Ensure within bounds (per-page)
            pdfX = pdfX.clamp(0.0, pdfWidth);
            pdfY = pdfY.clamp(0.0, pdfHeight);

            /// DRAG-DROP LOG - single consolidated log
            final resProfile = resolutionHelper.getDeviceProfile();

            LogService.send({
              'Timestamp': DateTime.now().toUtc().toIso8601String(),
              'action': 'drag_drop',
              'item_id': item.id,
              'item_text': item.text,
              'device_profile': resProfile,
              'screen_x': offset.dx,
              'screen_y': offset.dy,
              'local_x': localX.toStringAsFixed(2),
              'local_y': localY.toStringAsFixed(2),
              'zoom_level': widget.zoomLevel,
              'rendered_size':
                  '${renderedWidth.toStringAsFixed(0)}x${renderedHeight.toStringAsFixed(0)}',
              'scale_x': scaleX.toStringAsFixed(6),
              'scale_y': scaleY.toStringAsFixed(6),
              'page_index': calculatedPageIndex,
              'offset_x_correction': offsetXCorrection.toStringAsFixed(2),
              'offset_y_correction': offsetYCorrection.toStringAsFixed(2),
              'pdf_x_previous': item.x.toStringAsFixed(2),
              'pdf_y_previous': item.y.toStringAsFixed(2),
              'pdf_x_new': pdfX.toStringAsFixed(2),
              'pdf_y_new': pdfY.toStringAsFixed(2),
              'delta_x': (pdfX - item.x).toStringAsFixed(2),
              'delta_y': (pdfY - item.y).toStringAsFixed(2),
            });

            widget.onTextPositionChanged(item, pdfX, pdfY, calculatedPageIndex);
          }
        },
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: _buildTextWidget(
            item,
            isSelected: isSelected,
            isDragging: true,
          ),
        ),
        child: GestureDetector(
          onTap: () {
            widget.onTextSelected(item);
            _showEditTextModal(context, item);
          },
          child: _buildTextWidget(
            item,
            isSelected: isSelected,
            isDragging: false,
          ),
        ),
      ),
    );
  }

  /// Tạo widget hiển thị text
  Widget _buildTextWidget(
    PdfTextItem item, {
    bool isSelected = false,
    bool isDragging = false,
  }) {
    return Text(
      item.text,
      style: TextStyle(
        fontSize: item.fontSize,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
        shadows: isDragging
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Show modal để edit text
  void _showEditTextModal(BuildContext context, PdfTextItem item) {
    final textController = TextEditingController(text: item.text);
    final fontSizeController = TextEditingController(
      text: item.fontSize.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa text'),
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
            /// Delete button
            TextButton.icon(
              onPressed: () {
                widget.onTextDeleted?.call(item);
                Navigator.pop(dialogContext);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),

            /// Cancel button
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),

            /// Save button
            ElevatedButton(
              onPressed: () {
                try {
                  final newFontSize = double.parse(
                    fontSizeController.text.isNotEmpty
                        ? fontSizeController.text
                        : item.fontSize.toString(),
                  ).clamp(2.0, 72.0);

                  final updatedItem = item.copyWith(
                    text: textController.text,
                    fontSize: newFontSize,
                  );

                  // 📊 Log text edit
                  LogService.send({
                    'Timestamp': DateTime.now().toUtc().toIso8601String(),
                    'action': 'text_edited',
                    'item_id': item.id,
                    'old_text': item.text,
                    'new_text': updatedItem.text,
                    'old_font_size': item.fontSize,
                    'new_font_size': newFontSize,
                  });

                  widget.onTextPositionChanged(
                    updatedItem,
                    item.x,
                    item.y,
                    item.pageIndex,
                  );
                  Navigator.pop(dialogContext);
                } catch (e) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('❌ Kích thước không hợp lệ')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
