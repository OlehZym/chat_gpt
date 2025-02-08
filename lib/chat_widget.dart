//import 'dart:io';
import 'dart:typed_data';
//import 'package:chat_gpt/chat_widget.dart';
import 'package:chat_gpt/full_screen_image_viewer.dart';
import 'package:chat_gpt/main.dart';
import 'package:chat_gpt/message_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({required this.apiKey, super.key});

  final String apiKey;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode(debugLabel: 'TextField');
  bool _loading = false;

  // Список для хранения нескольких изображений
  final List<Uint8List> _selectedImageBytesList = [];

  final Logger logger = Logger(); // Добавление объекта logger

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: widget.apiKey);
    _chat = _model.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  // Открытие галереи и выбор нескольких изображений
  void _openFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images =
          await picker.pickMultiImage(); // Выбираем несколько изображений

      if (images.isNotEmpty) {
        final List<Uint8List> bytesList = await Future.wait(
          images.map((image) async => await image.readAsBytes()),
        );

        setState(() {
          _selectedImageBytesList.addAll(bytesList);
        });

        logger.i(
          'Изображения успешно выбраны: ${images.map((e) => e.name).join(', ')}',
        );
      }
    } catch (e) {
      logger.e("Ошибка при загрузке изображений: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _chat.history.toList();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemBuilder: (context, idx) {
                final content = history[idx];
                final text = content.parts
                    .whereType<TextPart>()
                    .map<String>((e) => e.text)
                    .join('');
                return MessageWidget(
                  text: text,
                  isFromUser: content.role == 'user',
                );
              },
              itemCount: history.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration(
                      context,
                      'Enter a prompt...',
                    ).copyWith(
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Скрепка (загрузка файлов)
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _openFile,
                          ),
                          // Отображение миниатюр изображений
                          if (_selectedImageBytesList.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Row(
                                spacing: 5,
                                children:
                                    _selectedImageBytesList.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final imageBytes = entry.value;
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              // Открытие изображения на весь экран
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => FullScreenImageViewer(
                                                        imageBytesList:
                                                            _selectedImageBytesList,
                                                        initialIndex: index,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              child: Image.memory(
                                                imageBytes,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          // Кнопка удаления (красный крестик)
                                          Positioned(
                                            top: -5,
                                            right: -5,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImageBytesList
                                                      .removeAt(index);
                                                });
                                              },
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  3,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                        ],
                      ),
                      contentPadding: EdgeInsets.only(
                        left: 1.0,
                      ), // Adjust the left padding here
                    ),
                    controller: _textController,
                    onSubmitted: (String value) {
                      _sendChatMessage(value);
                    },
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox.square(dimension: 15),
                IconButton(
                  onPressed:
                      _loading
                          ? null
                          : () async {
                            _sendChatMessage(_textController.text, );
                          },
                  icon:
                      _loading
                          ? const CircularProgressIndicator()
                          : Icon(
                            Icons.send,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text;

      if (text == null) {
        _showError('Empty response.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
