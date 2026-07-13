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
  bool _isFocused = false;
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
    final width = MediaQuery.of(context).size.width;

    // 🔥 breakpoint
    final bool isTV = width >= 1200;

    // 🎯 size config
    final double cardHeight = widget.height ?? (isTV ? 180 : 96);
    final double avatarRadius = isTV ? 56 : 28;
    final double titleSize = isTV ? 32 : 16;
    final double iconSize = isTV ? 28 : 16;
    final double paddingH = isTV ? 28 : 12;
    final double spacing = isTV ? 20 : 12;
    final double borderRadius = isTV ? 24 : 16;

    return FocusableActionDetector(
      onShowFocusHighlight: (value) {
        setState(() => _isFocused = value);
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) async {
          setState(() => _isPressed = false);
          await _playClickSound();
          widget.onTap?.call();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubCategoryScreen(category: widget.category),
            ),
          );
        },
        onTapCancel: () => setState(() => _isPressed = false),

        child: AnimatedScale(
          scale: _isPressed
              ? 0.96
              : _isFocused
              ? 1.05
              : 1.0,
          duration: const Duration(milliseconds: 120),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),

              // 🎨 gradient
              gradient: LinearGradient(
                colors: [
                  HSLColor.fromColor(
                    Color(int.parse(widget.category.color)),
                  ).withLightness(0.4).toColor(),
                  Color(int.parse(widget.category.color)),
                ],
              ),

              // ✨ shadow + focus glow
              boxShadow: [
                BoxShadow(
                  color: _isFocused
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: _isFocused ? 20 : 8,
                  spreadRadius: _isFocused ? 2 : 0,
                  offset: const Offset(0, 6),
                ),
              ],

              border: _isFocused
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH),
              child: Row(
                children: [
                  // 🔵 Avatar
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Color(int.parse(widget.category.color)),
                    child: Text(
                      _getInitials(widget.category.title),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isTV ? 26 : 14,
                      ),
                    ),
                  ),

                  SizedBox(width: spacing),

                  // 📝 Title
                  Expanded(
                    child: Text(
                      widget.category.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: titleSize,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: spacing),

                  // ➡️ Icon
                  Icon(
                    Icons.arrow_forward_ios,
                    size: iconSize,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
