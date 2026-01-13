import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/screens/sub_category_screen.dart';
import 'package:niemyetdientu/widgets/responsive_icon.dart';
import 'responsive_text.dart';

class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isPressed = false;
  final AudioPlayer _player = AudioPlayer();

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
        child: Container(
          decoration: BoxDecoration(
            color: Color(int.parse(widget.category.color)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ResponsiveIcon(
                  assetPath: widget.category.icon,
                  backgroundColor: Color(int.parse(widget.category.color)),
                ),
                const SizedBox(width: 12),
                Expanded(child: ResponsiveText(text: widget.category.title)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
