import 'dart:convert';
import 'dart:io';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:chatai/src/models/message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final openAI = OpenAI.instance.build(
    token: "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",
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
    enableLog: true,
  );

  List<String> _chatSessions = [];
  bool _isAnswering = false;
  bool _isTextFieldEmpty = true;
  String? _lastSession;
  List<Message> _messages = [];
  final _scrollController = ScrollController();
  final _textFieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textFieldController.addListener(() {
      if (_textFieldController.text.isEmpty != _isTextFieldEmpty) {
        setState(() {
          _isTextFieldEmpty = _textFieldController.text.isEmpty;
        });
      }
    });
    _readSetting();
    _loadLastSession();
    _loadChatSessions();
    if (_lastSession != null) {
      _loadMessages();
    }
  }

  _readSetting() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final prefsMap = <String, dynamic>{};
    for (String key in keys) {
      prefsMap[key] = prefs.get(key);
    }
    print(prefsMap);
  }

  _loadLastSession() async {
    final pref = await SharedPreferences.getInstance();
    pref.clear();
    final String? lastSession = pref.getString("LAST_SESSION");
    setState(() {
      _lastSession = lastSession;
    });
  }

  _loadChatSessions() async {
    final pref = await SharedPreferences.getInstance();
    final String? sessions = pref.getString("CHAT_SESSIONS");
    List<String> chatSessions = json.decode(sessions ?? '[]').cast<String>();

    setState(() {
      _chatSessions = chatSessions;
    });
  }

  _send(String msg) async {
    setState(() {
      _messages.add(
        Message(
            sender: MessageSender.USER,
            text: msg,
            time: DateFormat("HH:mm").format(DateTime.now())),
      );
      _isAnswering = true;
      _textFieldController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50)).then((_) => _scrollDown());

    final req = CompleteText(
      prompt: msg,
      maxTokens: 200,
      model: TextDavinci3Model(),
    );
    final res = await openAI.onCompletion(request: req);
    final recvMsg = Message(
      sender: MessageSender.BOT,
      text: res?.choices.first.text.trim() ?? 'Error',
      time: DateFormat("HH:mm").format(DateTime.now()),
    );
    _saveMessage();
    setState(() {
      _messages.add(recvMsg);
      _isAnswering = false;
    });
    Future.delayed(const Duration(milliseconds: 50)).then((_) => _scrollDown());
  }

  _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  _saveMessage() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString(_lastSession??'test', Message.encode(_messages));
  }

  _loadMessages() async {
    final pref = await SharedPreferences.getInstance();
    final String? encodedMsgs = pref.getString(_lastSession!);
    List<Message> msgs = encodedMsgs != null ? Message.decode(encodedMsgs) : [];

    setState(() {
      _messages = msgs;
    });
  }

  _buildPrompt() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _textFieldController,
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none),
                    hintText: 'Say something...',
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
              _isTextFieldEmpty
                  ? const SizedBox()
                  : IconButton(
                      onPressed: () {
                        _send(_textFieldController.text);
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 25,
                      ),
                    ),
            ]),
          ),
        ],
      ),
    );
  }

  _buildUserMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  message.time,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildSystemMessage(Message message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                Text(
                  message.time,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _buildDrawerTile(String title) {
    return ListTile(
      title: Text(title),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          // Code to delete the chat history goes here
        },
      ),
      onTap: () {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => ChatHistoryScreen()),
        // );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat with AI'),
          centerTitle: true,
        ),
        drawer: Drawer(
          child: ListView.builder(
            itemBuilder: (context, index) {
              return _buildDrawerTile(_chatSessions[index]);
            },
            itemCount: _chatSessions.length,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20)),
                  child: ListView.builder(
                      padding: const EdgeInsets.only(top: 15),
                      itemCount: _messages.length,
                      controller: _scrollController,
                      itemBuilder: (BuildContext context, int index) {
                        final Message message = _messages[index];
                        return message.isUser()
                            ? _buildUserMessage(_messages[index])
                            : _buildSystemMessage(_messages[index]);
                      }),
                ),
              ),
            ),
            _buildPrompt(),
          ],
        ),
      ),
    );
  }
}
