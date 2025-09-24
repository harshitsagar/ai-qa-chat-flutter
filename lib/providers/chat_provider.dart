import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';

class ChatNotifier extends StateNotifier<List<Message>> {
  final ApiService apiService;
  bool _isLoading = false;

  ChatNotifier(this.apiService) : super([]);

  void addMessage(Message message) {
    state = [...state, message];
  }

  void updateLastMessage(String newContent) {
    if (state.isEmpty) return;

    final lastMessage = state.last;
    if (lastMessage.role == 'assistant') {
      state = [
        ...state.sublist(0, state.length - 1),
        lastMessage.copyWith(content: lastMessage.content + newContent),
      ];
    }
  }

  Future<void> sendMessage(String userMessage) async {
    if (_isLoading) return;

    _isLoading = true;

    try {
      // Add user message
      final userMsg = Message(role: 'user', content: userMessage);
      addMessage(userMsg);

      // Add empty assistant message for streaming
      final assistantMsg = Message(role: 'assistant', content: '');
      addMessage(assistantMsg);

      // Send entire conversation history (excluding the empty assistant message)
      final messagesToSend = state.sublist(0, state.length - 1);

      print('Sending ${messagesToSend.length} messages to backend');

      await for (final chunk in apiService.sendMessage(messagesToSend)) {
        print('Updating with chunk: $chunk');
        updateLastMessage(chunk);
      }

      print('Message streaming completed');
    } catch (e) {
      print('Error in sendMessage: $e');
      // Update with error message
      if (state.isNotEmpty && state.last.role == 'assistant') {
        state = [
          ...state.sublist(0, state.length - 1),
          Message(role: 'assistant', content: 'Error: $e'),
        ];
      }
    } finally {
      _isLoading = false;
    }
  }

  void clearChat() {
    state = [];
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  // Try different URLs based on platform
  // return ApiService(baseUrl: 'http://10.0.2.2:8000'); // Android emulator
  return ApiService(baseUrl: 'http://localhost:8000'); // iOS simulator
  // return ApiService(baseUrl: 'http://192.168.1.100:8000'); // Real device (replace with your computer IP)
});

final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return ChatNotifier(apiService);
});