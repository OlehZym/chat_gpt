//import 'dart:io';
import 'package:chat_gpt/chat_screen.dart';
// import 'package:chat_gpt/chat_widget.dart';
// import 'package:chat_gpt/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart'; // Для работы с изображениями
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:logger/logger.dart';
// import 'package:url_launcher/link.dart';
// import 'dart:typed_data';

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
