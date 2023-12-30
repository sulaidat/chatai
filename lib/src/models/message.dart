import 'dart:convert';

class Message {
  final String text;
  final MessageSender sender;
  final String time;
  late BotMessageState state;

  bool isUser() => sender == MessageSender.USER;

  Message({
    required this.sender,
    this.text = '',
    this.time = '00:00',
    this.state = BotMessageState.CANPLAY,
  });

  factory Message.fromJson(Map<String, dynamic> jsonData) {
    return Message(
      text: jsonData['text'],
      sender: MessageSender.values[jsonData['sender']],
      time: jsonData['time'],
      state: BotMessageState.values[jsonData['state']],
    );
  }

  static Map<String, dynamic> toMap(Message msg) => {
        'text': msg.text,
        'sender': msg.sender.index,
        'time': msg.time,
        'state': msg.state.index,
      };

  static String encode(List<Message> msgs) => json.encode(
        msgs.map<Map<String, dynamic>>((msg) => Message.toMap(msg)).toList(),
      );

  static List<Message> decode(String msgs) =>
      (json.decode(msgs) as List<dynamic>)
          .map<Message>((item) => Message.fromJson(item))
          .toList();
}

enum MessageSender { USER, BOT }

enum BotMessageState {
  NULL,
  LOADING,
  SPEAKING,
  CANPLAY,
}
