import 'package:flutter/material.dart';
import 'package:niemyetdientu/model/pdf_text_item.dart';

class PdfEditorOverlay extends StatefulWidget {
  final List<PdfTextItem> textItems;
  final Function(PdfTextItem) onTextSelected;
  final Function(PdfTextItem, double, double) onTextPositionChanged;
  final Function(PdfTextItem, double)? onTextSizeChanged;
  final double zoomLevel;
  final Matrix4? transformationMatrix;
  final PdfTextItem? selectedItem;

  const PdfEditorOverlay({
    super.key,
    required this.textItems,
    required this.onTextSelected,
    required this.onTextPositionChanged,
    this.onTextSizeChanged,
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

  /// Track initial font size khi bắt đầu pinch
  double _initialFontSize = 16.0;

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

    return Positioned(
      left: item.x,
      top: item.y,
      child: DragTarget<PdfTextItem>(
        onAccept: (draggedItem) {
          /// Không cần xử lý ở đây vì Draggable sẽ xử lý
        },
        builder: (context, candidateData, rejectedData) {
          return Draggable<PdfTextItem>(
            data: item,
            feedback: _buildTextWidget(
              item,
              isSelected: true,
              isDragging: true,
            ),
            onDragStarted: () {
              /// Bắt đầu kéo
              draggedItem = item;
              widget.onTextSelected(item);
            },
            onDraggableCanceled: (velocity, offset) {
              /// Kết thúc kéo
              draggedItem = null;

              /// Cập nhật vị trí mới - convert global offset sang local coords
              final stackRenderBox =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (stackRenderBox != null) {
                final stackGlobalOffset = stackRenderBox.localToGlobal(
                  Offset.zero,
                );

                /// Local coords của drag position (trước inverse transformation)
                var localX = (offset.dx - stackGlobalOffset.dx).clamp(
                  0.0,
                  double.infinity,
                );
                var localY = (offset.dy - stackGlobalOffset.dy).clamp(
                  0.0,
                  double.infinity,
                );

                /// Inverse transformation matrix để get actual coords
                /// (undo InteractiveViewer's transform)
                final matrix = widget.transformationMatrix;
                if (matrix != null) {
                  try {
                    /// Extract scale từ transformation matrix
                    final scale = matrix.getMaxScaleOnAxis();

                    if (scale > 0) {
                      localX = localX / scale;
                      localY = localY / scale;
                    }
                  } catch (e) {
                    debugPrint('❌ Lỗi inverse matrix: $e');
                  }
                }

                widget.onTextPositionChanged(item, localX, localY);
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
              },
              onScaleUpdate: isSelected
                  ? (ScaleUpdateDetails details) {
                      /// Resize text khi pinch nếu item được chọn
                      if (details.pointerCount == 2) {
                        final newFontSize = (_initialFontSize * details.scale)
                            .clamp(8.0, 72.0);
                        widget.onTextSizeChanged?.call(item, newFontSize);
                      }
                    }
                  : null,
              onScaleStart: isSelected
                  ? (ScaleStartDetails details) {
                      _initialFontSize = item.fontSize;
                    }
                  : null,
              child: _buildTextWidget(
                item,
                isSelected: isSelected,
                isDragging: false,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Tạo widget hiển thị text
  Widget _buildTextWidget(
    PdfTextItem item, {
    bool isSelected = false,
    bool isDragging = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.red : Colors.blue.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white.withOpacity(isDragging ? 0.7 : 0.9),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 2,
            ),
          if (isDragging)
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Text(
        item.text,
        style: TextStyle(
          fontSize: item.fontSize,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
