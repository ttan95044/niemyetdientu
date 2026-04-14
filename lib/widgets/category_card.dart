import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/screens/sub_category_screen.dart';

class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback? onTap;
  final double? height;

  const CategoryCard({
    super.key,
    required this.category,
    this.onTap,
    this.height,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;
  final AudioPlayer _player = AudioPlayer();

  String _getInitials(String title) {
    final parts = title.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final word = parts[0];
      return word.length <= 2
          ? word.toUpperCase()
          : word.substring(0, 2).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _playClickSound() async {
    try {
      await _player.play(AssetSource('sounds/pick.mp3'));
    } catch (e) {
      debugPrint("Không phát được âm thanh: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await _playClickSound();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubCategoryScreen(category: widget.category),
          ),
        );
      },

      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 50),
        curve: Curves.easeOut,
        child: SizedBox(
          height: widget.height ?? 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                // gentle gradient based on category color
                gradient: LinearGradient(
                  colors: [
                    HSLColor.fromColor(Color(int.parse(widget.category.color)))
                        .withLightness(
                          (HSLColor.fromColor(
                                    Color(int.parse(widget.category.color)),
                                  ).lightness -
                                  0.06)
                              .clamp(0.0, 1.0),
                        )
                        .toColor(),
                    Color(int.parse(widget.category.color)),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(int.parse(widget.category.color)),
                      child: Text(
                        _getInitials(widget.category.title),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
