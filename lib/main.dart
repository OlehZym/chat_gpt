//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Для работы с изображениями
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/link.dart';
import 'dart:typed_data';

void main() {
  runApp(const GenerativeAISample());
}

class GenerativeAISample extends StatelessWidget {
  const GenerativeAISample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter + Generative AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 171, 222, 244),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'Flutter + Generative AI'),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? apiKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body:
          apiKey == null
              ? ApiKeyWidget(
                onSubmitted: (key) {
                  setState(() => apiKey = key);
                },
              )
              : ChatWidget(apiKey: apiKey!),
    );
  }
}

class ApiKeyWidget extends StatelessWidget {
  ApiKeyWidget({required this.onSubmitted, super.key});

  final ValueChanged<String> onSubmitted;
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To use the Gemini API, you\'ll need an API key. '
              'If you don\'t already have one, '
              'create a key in Google AI Studio.',
            ),
            const SizedBox(height: 8),
            Link(
              uri: Uri.https('makersuite.google.com', '/app/apikey'),
              target: LinkTarget.blank,
              builder:
                  (context, followLink) => TextButton(
                    onPressed: followLink,
                    child: const Text('Get an API Key'),
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: textFieldDecoration(
                      context,
                      'Enter your API key',
                    ),
                    controller: _textController,
                    onSubmitted: (value) {
                      onSubmitted(value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    onSubmitted(_textController.value.text);
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
  List<Uint8List> _selectedImageBytesList = [];

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
      final List<XFile>? images =
          await picker.pickMultiImage(); // Выбираем несколько изображений

      if (images != null && images.isNotEmpty) {
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
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                spacing: 5,
                                children:
                                    _selectedImageBytesList.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index =
                                          entry.key; // Получаем индекс
                                      final imageBytes =
                                          entry.value; // Получаем изображение
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
                            _sendChatMessage(_textController.text);
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

class FullScreenImageViewer extends StatefulWidget {
  final List<Uint8List> imageBytesList;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageBytesList,
    required this.initialIndex,
  });

  @override
  FullScreenImageViewerState createState() => FullScreenImageViewerState();
}

class FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _nextImage() {
    setState(() {
      _currentIndex =
          (_currentIndex + 1) %
          widget.imageBytesList.length; // Переключение на следующее изображение
    });
  }

  void _previousImage() {
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + widget.imageBytesList.length) %
          widget
              .imageBytesList
              .length; // Переключение на предыдущее изображение
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Full Screen Image')),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.memory(widget.imageBytesList[_currentIndex]),
            ),
          ),
          // Стрелка назад
          Positioned(
            left: 16,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: _previousImage,
            ),
          ),
          // Стрелка вперёд
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height / 2 - 24,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: _nextImage,
            ),
          ),
        ],
      ),
    );
  }
}

class MessageWidget extends StatelessWidget {
  const MessageWidget({
    super.key,
    required this.text,
    required this.isFromUser,
  });

  final String text;
  final bool isFromUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color:
                  isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            margin: const EdgeInsets.only(bottom: 8),
            child: MarkdownBody(data: text),
          ),
        ),
      ],
    );
  }
}

InputDecoration textFieldDecoration(BuildContext context, String hintText) =>
    InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
      ),
    );
