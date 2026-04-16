import 'package:flutter/material.dart';

class EditTextForm extends StatefulWidget {
  final Function(String) onAddText;

  const EditTextForm({super.key, required this.onAddText});

  @override
  State<EditTextForm> createState() => _EditTextFormState();
}

class _EditTextFormState extends State<EditTextForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addText() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng nhập text'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    widget.onAddText(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /// Biểu tượng
        const Icon(Icons.text_fields, color: Colors.blue),
        const SizedBox(width: 8),

        /// Input field
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Nhập text cần thêm vào PDF...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (_) => _addText(),
          ),
        ),
        const SizedBox(width: 8),

        /// Nút thêm text
        ElevatedButton.icon(
          onPressed: _addText,
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        ),
      ],
    );
  }
}
