import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';

class PdfEditorOverlay extends StatefulWidget {
  final List<PdfTextItem> textItems;
  final Function(PdfTextItem) onTextSelected;
  final Function(PdfTextItem, double, double) onTextPositionChanged;
  final Function(PdfTextItem)? onTextDeleted;
  final double zoomLevel;
  final Matrix4? transformationMatrix;
  final PdfTextItem? selectedItem;

  const PdfEditorOverlay({
    super.key,
    required this.textItems,
    required this.onTextSelected,
    required this.onTextPositionChanged,
    this.onTextDeleted,
    this.zoomLevel = 1.0,
    this.transformationMatrix,
    this.selectedItem,
  });

  @override
  State<PdfEditorOverlay> createState() => _PdfEditorOverlayState();
}

class _PdfEditorOverlayState extends State<PdfEditorOverlay> {
  /// Để theo dõi vị trí khi drag
  PdfTextItem? draggedItem;

  /// Global key để lấy position của Stack
  final GlobalKey _stackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      children: [
        /// Khu vực background để detect tap và update position từ drag
        GestureDetector(
          onTap: () {
            /// Bỏ chọn khi tap vào vùng trống
            widget.onTextSelected(PdfTextItem(id: '', text: '', x: 0, y: 0));
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
    const pdfPageWidth = 612.0;
    const pdfPageHeight = 792.0;

    // Get stack size
    final stackRenderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final stackSize = stackRenderBox?.size ?? const Size(600, 800);

    // 📐 DEBUG: Log stack size lần đầu
    if (item == widget.textItems.firstOrNull) {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('📐 EDITOR UI SIZE:');
      debugPrint(
        '   → Stack: ${stackSize.width.toStringAsFixed(2)}×${stackSize.height.toStringAsFixed(2)} pixels',
      );
      debugPrint(
        '   → Aspect ratio: ${(stackSize.width / stackSize.height).toStringAsFixed(4)}',
      );
      debugPrint(
        '   → PDF aspect: ${(pdfPageWidth / pdfPageHeight).toStringAsFixed(4)} (612/792)',
      );
      debugPrint('═══════════════════════════════════════════════════');
      debugPrint('');
    }

    // Position tại zoom = 1.0 (before InteractiveViewer's matrix transform)
    final screenX = item.x * (stackSize.width / pdfPageWidth);
    final screenY = item.y * (stackSize.height / pdfPageHeight);

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
            // Khi zoom = 2x, offset đã bao gồm 2x scale, cần chia cho 2
            localX = localX / widget.zoomLevel;
            localY = localY / widget.zoomLevel;

            /// Convert từ screen pixels sang PDF coordinates
            const pdfPageWidth = 612.0;
            const pdfPageHeight = 792.0;

            var pdfX = localX * (pdfPageWidth / stackSize.width);
            var pdfY = localY * (pdfPageHeight / stackSize.height);

            // Ensure within bounds
            pdfX = pdfX.clamp(0.0, pdfPageWidth);
            pdfY = pdfY.clamp(0.0, pdfPageHeight);

            // 📐 DEBUG: Log drag position conversion
            debugPrint('');
            debugPrint('🎯 DROP "${item.text}":');
            debugPrint(
              '   Screen offset (global): dx=${offset.dx.toStringAsFixed(2)}, dy=${offset.dy.toStringAsFixed(2)}',
            );
            debugPrint(
              '   Stack local (pre-zoom): x=${(offset.dx - stackGlobalOffset.dx).toStringAsFixed(2)}, y=${(offset.dy - stackGlobalOffset.dy).toStringAsFixed(2)}',
            );
            debugPrint(
              '   After zoom undo (÷${widget.zoomLevel.toStringAsFixed(2)}): x=${localX.toStringAsFixed(2)}, y=${localY.toStringAsFixed(2)}',
            );
            debugPrint(
              '   Stack size: ${stackSize.width.toStringAsFixed(2)}×${stackSize.height.toStringAsFixed(2)}',
            );
            debugPrint(
              '   → PDF coords: x=${pdfX.toStringAsFixed(2)}, y=${pdfY.toStringAsFixed(2)}',
            );

            widget.onTextPositionChanged(item, pdfX, pdfY);
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
            const Spacer(),

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
                  widget.onTextPositionChanged(updatedItem, item.x, item.y);
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
