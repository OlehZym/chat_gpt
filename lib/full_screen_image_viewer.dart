//import 'dart:io';
import 'dart:typed_data';
// import 'package:chat_gpt/full_screen_image_viewer.dart';
// import 'package:chat_gpt/main.dart';
import 'package:flutter/material.dart';

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
