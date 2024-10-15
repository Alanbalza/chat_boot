import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

const String apiKey = "AIzaSyA-DsUGNFOHWfNV5DmgFUkva2JaPyLLHHg";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _speechText = '';
  bool _isConnectedToWifi = true;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    _chat = _model.startChat();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    requestMicrophonePermission();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    _updateConnectionStatus(connectivityResult);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    setState(() {
      _isConnectedToWifi = result == ConnectivityResult.wifi;
    });
  }

  void _scrollDown() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if ((maxScroll - currentScroll) <= 200) {
        _scrollController.jumpTo(maxScroll);
      }
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-EN");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Future<void> _sendChatMessage(String message) async {
    String formattedTime = DateFormat('kk:mm').format(DateTime.now());
    setState(() {
      _messages
          .add(ChatMessage(text: message, isUser: true, time: formattedTime));
    });
    try {
      _messages
          .add(ChatMessage(text: '...', isUser: false, time: formattedTime));
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text ?? 'No se recibió respuesta';
      setState(() {
        _messages.removeLast();
        _messages
            .add(ChatMessage(text: text, isUser: false, time: formattedTime));
      });
      _scrollDown();
      await _speak(text);
    } catch (e) {
      setState(() {
        _messages.add(
            ChatMessage(text: 'Error: $e', isUser: false, time: formattedTime));
      });
    } finally {
      _textController.clear();
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done') {
          _stopListening();
        }
      },
      onError: (val) => print('Error del reconocimiento de voz: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _speechText = val.recognizedWords;
            _textController.text = _speechText;
          });
        },
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Mi chat inteligente', style: TextStyle(fontSize: 22)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? Colors.redAccent : Colors.tealAccent,
                    size: 28,
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
                Expanded(
                  child: TextField(
                    onSubmitted: _isConnectedToWifi ? _sendChatMessage : null,
                    controller: _textController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[800],
                      hintText: 'Escribe un mensaje...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: _isConnectedToWifi
                      ? Colors.tealAccent
                      : Colors.grey,
                  iconSize: 28,
                  onPressed: _isConnectedToWifi
                      ? () => _sendChatMessage(_textController.text)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser)
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/logo.jpeg'),
                  radius: 20,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF4A4A6A)
                        : const Color(0xFF3A3A5A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message.time,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
