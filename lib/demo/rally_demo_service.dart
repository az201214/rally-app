import 'package:flutter/foundation.dart';

class RallyDemoService extends ChangeNotifier {
  RallyDemoService._();

  static final RallyDemoService instance = RallyDemoService._();

  final List<String> _chatMessages = <String>[];

  Duration get matchmakingDelay => const Duration(milliseconds: 4200);

  List<String> get chatMessages => List<String>.unmodifiable(_chatMessages);

  void sendChatMessage(String message) {
    final clean = message.trim();
    if (clean.isEmpty) return;
    _chatMessages.add(clean);
    notifyListeners();
  }

  void resetSession() {
    _chatMessages.clear();
    notifyListeners();
  }
}
