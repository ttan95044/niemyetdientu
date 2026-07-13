import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:niemyetdientu/model/category_model.dart';
import 'package:niemyetdientu/model/chatbot_result.dart';
import 'package:niemyetdientu/screens/sub_category_screen.dart';
import 'package:niemyetdientu/service/category_service.dart';
import 'package:niemyetdientu/service/chatbot_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

class VoiceAssistantPopup extends StatefulWidget {
  const VoiceAssistantPopup({super.key});

  @override
  State<VoiceAssistantPopup> createState() => _VoiceAssistantPopupState();
}

class _VoiceAssistantPopupState extends State<VoiceAssistantPopup> {
  late stt.SpeechToText _speech;
  final TextEditingController _textController = TextEditingController();

  List<CategoryModel> categories = [];

  bool _isListening = false;
  bool _isLoading = false;
  double _soundLevel = 0.0;
  String? _initError;

  final List<_ChatMessage> _messages = [];

  final List<String> _logs = [];
  String _micStatus = "Chưa bắt đầu";

  bool get _hasError => _logs.any((log) => log.contains("❌"));

  bool _isDisposed = false;

  // ignore: unused_field
  bool _hasStarted = false;

  String? _lastError;

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();
    loadCategories();

    // 👇 reset ngay khi vào màn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetSpeech();
    });
  }

  //show log
  void _log(String message) {
    debugPrint(message);

    if (!mounted) return;

    setState(() {
      _logs.add(message);
    });
  }

  Future<void> _resetSpeech() async {
    try {
      await _speech.stop();
      await _speech.cancel();

      _speech = stt.SpeechToText();

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _micStatus = "Chưa bắt đầu";
        _soundLevel = 0;
        _initError = null;
      });

      _log("🔄 Reset mic");
    } catch (e) {
      _log("❌ Reset lỗi: $e");
    }
  }

  Future<void> loadCategories() async {
    // gọi API của bạn
    categories = await CategoryService.fetchCategories();
  }

  @override
  void dispose() {
    _speech.stop();
    _speech.cancel();
    _isDisposed = true;
    _textController.dispose();
    super.dispose();
  }

  Future<String?> _preferredLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isEmpty) return null;
      final vi = locales.firstWhere(
        (l) => l.localeId.toLowerCase().startsWith('vi'),
        orElse: () => locales.first,
      );
      return vi.localeId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    _initError = null;
    _hasStarted = false;
    // 👇 luôn tạo instance mới
    _speech = stt.SpeechToText();
    // 👇 reset sạch trước khi init lại
    await _speech.stop();
    await _speech.cancel();

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _micStatus = "🔄 Đang khởi động...";
    });

    _log("🎤 Bắt đầu xin quyền micro...");

    final status = await Permission.microphone.request();

    _log("Permission: $status");

    if (status == PermissionStatus.denied) {
      setState(() {
        _isListening = false;
        _micStatus = "❌ Không có quyền micro";
      });
      return;
    }

    if (status == PermissionStatus.permanentlyDenied) {
      _log("❌ Bị chặn vĩnh viễn → mở settings");
      openAppSettings();
      return;
    }

    bool available = false;

    try {
      _log("⚙️ Init speech...");
      available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted || _isDisposed) return; // 👈 thêm dòng này

          _log("📡 Status: $status");

          setState(() {
            if (status == "listening") {
              _isListening = true;
              _micStatus = "🎤 Đang nghe...";
            } else if (status == "notListening") {
              _isListening = false;
              _micStatus = "⏹ Đã dừng";
            } else if (status == "done") {
              _isListening = false;
              _micStatus = "✅ Hoàn tất";
            } else {
              _micStatus = status;
            }
          });
        },
        onError: (error) {
          if (!mounted || _isDisposed) return;

          final msg = "❌ ${error.errorMsg}";
          _lastError = msg; // 👈 lưu lại lỗi thật

          _log(msg);

          setState(() {
            _isListening = false;
            _micStatus = msg;
          });
        },
      );
    } catch (e) {
      _log("💥 Exception init: $e");
    }

    _log("Available: $available");

    if (!available) {
      _log("❌ Device không hỗ trợ speech hoặc thiếu service");

      setState(() {
        _micStatus = "❌ Thiết bị không hỗ trợ Speech";
        _initError = _micStatus;
      });

      return;
    }

    final localeId = await _preferredLocale();

    if (localeId == null) {
      setState(() {
        _micStatus = "❌ Không có ngôn ngữ phù hợp";
        _initError = _micStatus;
      });
      return;
    }
    _log("🌍 Locale: $localeId");

    setState(() {
      _micStatus = "🎤 Đang khởi động...";
    });

    _speech.listen(
      onResult: (result) {
        _hasStarted = true;

        if (!mounted || _isDisposed) return;

        setState(() {
          _textController.text = result.recognizedWords;
        });

        // 👇 nếu là kết quả cuối thì dừng luôn
        if (result.finalResult) {
          _stopListening();
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted || _isDisposed) return;

        if (level > 0) _hasStarted = true;

        setState(() {
          _soundLevel = level;

          // 👇 FIX CỨNG: nếu có âm thanh thì chắc chắn đang nghe
          if (!_isListening && level > 1) {
            _isListening = true;
            _micStatus = "🎤 Đang nghe...";
          }
        });
      },
      localeId: localeId,
      partialResults: true,
    );

    // 👇 auto stop sau 6s nếu user không nói nữa
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted || _isDisposed) return;

      if (_isListening) {
        _stopListening();
        _log("⏱ Auto stop sau timeout");
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _isDisposed) return;

      if (!_isListening && !_hasStarted) {
        _micStatus = "⚠️ Đang chờ mic...";
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _isDisposed) return;

      if (!_hasStarted) {
        _speech.stop();

        final errorMsg = _lastError ?? "❌ Không có âm thanh (timeout)";

        setState(() {
          _micStatus = errorMsg;
          _initError = errorMsg;
          _isListening = false;
        });

        _log("❌ Timeout: không có âm thanh");
      }
    });
  }

  Future<void> _stopListening() async {
    try {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
        _micStatus = "⏹ Đã dừng"; // 👈 ép trạng thái luôn
      });
    } catch (e) {
      _log("❌ Stop lỗi: $e");
    }
  }

  String _buildMarkdown(ChatbotResult data) {
    final sb = StringBuffer();

    if (data.name.isNotEmpty) {
      sb.writeln('### ${data.name}');
    }
    if (data.decision.isNotEmpty) {
      sb.writeln('- Số quyết định: ${data.decision}');
    }
    if (data.typeName.isNotEmpty) {
      sb.writeln('- Loại: ${data.typeName}');
    }
    if (data.fieldName.isNotEmpty) {
      sb.writeln('- Lĩnh vực: ${data.fieldName}');
    }

    sb.writeln('- Đã phát hành: ${data.isPublished ? "Có" : "Không"}');

    return sb.toString();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(sender: "user", text: text.trim()));
      _isLoading = true;
      _textController.clear();
    });

    try {
      // 🔹 Gọi API nội bộ
      final result = await ChatbotService.sendPrompt(text);

      // ❌ bỏ regex luôn
      final field = result.fieldName;

      setState(() {
        _messages.add(
          _ChatMessage(
            sender: "ai",
            text: _buildMarkdown(result), // 👈 convert sang text hiển thị
            field: field,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(sender: "ai", text: "❌ Lỗi: $e"));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  CategoryModel? findCategoryByField(
    String field,
    List<CategoryModel> categories,
  ) {
    String normalize(String text) {
      return text.toLowerCase().replaceAll('-', '').replaceAll(' ', '').trim();
    }

    try {
      return categories.firstWhere(
        (c) => normalize(c.title) == normalize(field),
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildMessageWithClickableField(_ChatMessage message, bool isUser) {
    final lines = message.text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.contains('Lĩnh vực:')) {
          final field = message.field ?? '';

          return Row(
            children: [
              Text(
                '• Lĩnh vực: ',
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
              GestureDetector(
                onTap: () {
                  final category = findCategoryByField(
                    field,
                    categories, // 👈 nhớ có list này
                  );

                  if (category != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubCategoryScreen(category: category),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Không tìm thấy lĩnh vực")),
                    );
                  }
                },
                child: Text(
                  field,
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: TextStyle(color: isUser ? Colors.white : Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Trợ lý AI"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      final isUser = message.sender == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isUser
                                ? Colors.blue.shade600
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: message.field != null
                              ? _buildMessageWithClickableField(message, isUser)
                              : MarkdownBody(
                                  data: message.text,
                                  onTapLink: (text, href, title) async {
                                    if (href == null) return;
                                    final uri = Uri.tryParse(href);
                                    if (uri == null) return;
                                    await launchUrl(uri);
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                // small diagnostics row so you can see init error / sound level on device
                if (_initError != null || _soundLevel > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        if (_initError != null)
                          Expanded(
                            child: Text(
                              'Mic init error: ${_initError}',
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          width: 120,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_soundLevel / 15).clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _soundLevel > 2
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // cảnh báo riêng cho Android TV / ROM China
                if (_micStatus.contains("error_language_not_supported"))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "⚠️ Thiết bị không hỗ trợ giọng nói",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                // 👇 debug log hiển thị ở đây
                if (_hasError)
                  Container(
                    width: double.infinity,
                    height: 200,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _logs.map((log) {
                          final isError = log.contains("❌");

                          return Text(
                            log,
                            style: TextStyle(
                              color: isError
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                // 👇 trạng thái mic
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _micStatus,
                    style: TextStyle(
                      color: _micStatus.contains("❌")
                          ? Colors.red
                          : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onSubmitted: (v) => _sendMessage(v),
                          decoration: InputDecoration(
                            hintText: 'Nhập tin nhắn hoặc nói...',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: _textController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () =>
                                        setState(() => _textController.clear()),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _isListening ? _stopListening : _startListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? Colors.redAccent
                                : Colors.blue.shade600,
                            boxShadow: [
                              if (_isListening)
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.28),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _isLoading
                            ? null
                            : () => _sendMessage(_textController.text),
                        icon: Icon(
                          Icons.send,
                          color: _isLoading
                              ? Colors.grey
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  final String? field;

  _ChatMessage({required this.sender, required this.text, this.field});
}
