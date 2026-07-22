import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/mesh_database.dart';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  String _currentPeerId = '';
  final String localDeviceId; 
  
  ChatProvider(this.localDeviceId);

  List<Map<String, dynamic>> get messages => _messages;
  String get currentPeerId => _currentPeerId;

  Future<void> syncMessagesWithBackend() async {
    try {
      final String base = AuthService.baseUrl;
      final response = await http.get(Uri.parse('$base/api/messages'))
          .timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final List<dynamic> serverMsgs = jsonDecode(response.body);
        for (var msg in serverMsgs) {
          if (msg is Map) {
            final Map<String, dynamic> msgMap = Map<String, dynamic>.from(msg);
            
            final messageId = msgMap['messageId']?.toString() ?? '';
            if (messageId.isEmpty) continue;
            
            final timestampVal = msgMap['timestamp'];
            final int timestamp = (timestampVal is num)
                ? timestampVal.toInt()
                : (int.tryParse(timestampVal?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch);

            final ttlVal = msgMap['ttl'];
            final int ttl = (ttlVal is num) ? ttlVal.toInt() : 5;

            final hopsVal = msgMap['hops'];
            final int hops = (hopsVal is num) ? hopsVal.toInt() : 0;

            await MeshDatabase.instance.insertMessage({
              'messageId': messageId,
              'senderId': msgMap['senderId']?.toString() ?? '',
              'receiverId': msgMap['receiverId']?.toString() ?? '',
              'content': msgMap['content']?.toString() ?? '',
              'timestamp': timestamp,
              'ttl': ttl,
              'hops': hops,
              'status': msgMap['status']?.toString() ?? 'Sent',
            });
          }
        }
      }
    } catch (e) {
      debugPrint("API messages sync failed: $e");
    }
  }

  Future<void> loadMessages(String peerId) async {
    _currentPeerId = peerId;
    await syncMessagesWithBackend();
    final results = await MeshDatabase.instance.getMessagesForChat(peerId, localDeviceId);
    _messages = List<Map<String, dynamic>>.from(results);
    notifyListeners();
  }

  Future<void> loadAllMessages() async {
    _currentPeerId = ''; // All chats
    await syncMessagesWithBackend();
    final results = await MeshDatabase.instance.getAllMessages();
    _messages = List<Map<String, dynamic>>.from(results);
    notifyListeners();
  }

  void addMessageLocally(Map<String, dynamic> message) {
    // Only add if it belongs to the current chat or is broadcast
    if (_currentPeerId.isEmpty || 
        message['receiverId'] == 'BROADCAST' || 
        message['receiverId'] == 'AUTHORITIES' || 
        message['senderId'] == _currentPeerId || 
        message['receiverId'] == _currentPeerId ||
        message['senderId'] == localDeviceId) {
      _messages.add(message);
      // Sort to ensure order
      _messages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      notifyListeners();
    }
  }
}
