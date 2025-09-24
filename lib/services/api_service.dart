import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/message_model.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl;

  ApiService({required this.baseUrl});

  Stream<String> sendMessage(List<Message> messages) async* {
    try {
      // Convert messages to JSON
      final messageList = messages.map((msg) => msg.toJson()).toList();

      print('Sending request to: $baseUrl/chat');
      print('Message count: ${messageList.length}');

      // Make POST request with streaming
      final response = await _dio.post(
        '$baseUrl/chat',
        data: messageList,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
        ),
      );

      print('Response status: ${response.statusCode}');

      // Handle stream response
      final responseStream = response.data as ResponseBody;
      final stream = responseStream.stream;

      String buffer = '';

      await for (var chunk in stream) {
        if (chunk is List<int>) {
          final String chunkString = utf8.decode(chunk);
          buffer += chunkString;

          // Split by double newlines (SSE format)
          final events = buffer.split('\n\n');
          buffer = events.last; // Keep incomplete event

          for (final event in events.sublist(0, events.length - 1)) {
            final lines = event.split('\n');
            for (final line in lines) {
              if (line.startsWith('data: ')) {
                final data = line.substring(6);
                if (data == '[DONE]') {
                  print('Stream completed');
                  return;
                }

                if (data.isNotEmpty) {
                  try {
                    final jsonData = json.decode(data);
                    if (jsonData['content'] != null) {
                      final content = jsonData['content'];
                      print('Received chunk: $content');
                      yield content;
                    }
                  } catch (e) {
                    print('JSON parse error: $e for data: $data');
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('$baseUrl/health');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }
}