//import 'dart:io';
//import 'package:chat_gpt/chat_screen.dart';
import 'package:chat_gpt/api_key_widget.dart';
import 'package:chat_gpt/chat_widget.dart';
//import 'package:chat_gpt/main.dart';
import 'package:flutter/material.dart';

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
