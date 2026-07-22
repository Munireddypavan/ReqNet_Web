import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/mesh_database.dart';
import '../services/auth_service.dart';

class MeshProvider extends ChangeNotifier {
  int _connectedNodesCount = 0;
  final String _signalStrength = 'High';
  final List<String> _activeProtocols = ['Bluetooth LE', 'Wi-Fi Direct', 'LoRa Relay'];
  final List<Map<String, dynamic>> _connectedPeers = [];
  List<Map<String, dynamic>> _discoveredNodes = [];

  int get connectedNodesCount => _connectedNodesCount;
  String get signalStrength => _signalStrength;
  List<String> get activeProtocols => _activeProtocols;
  List<Map<String, dynamic>> get connectedPeers => _connectedPeers;
  List<Map<String, dynamic>> get discoveredNodes => _discoveredNodes;

  bool isProtocolActive(String protocol) => _activeProtocols.contains(protocol);

  void toggleProtocol(String protocol, bool isActive) {
    if (isActive && !_activeProtocols.contains(protocol)) {
      _activeProtocols.add(protocol);
    } else if (!isActive) {
      _activeProtocols.remove(protocol);
    }
    notifyListeners();
  }

  void updateConnectedNodesCount(int count) {
    _connectedNodesCount = count;
    notifyListeners();
  }

  void addPeer(String id, String name) {
    _connectedPeers.add({'id': id, 'name': name});
    _connectedNodesCount = _connectedPeers.length;
    notifyListeners();
  }

  void removePeer(String id) {
    _connectedPeers.removeWhere((peer) => peer['id'] == id);
    _connectedNodesCount = _connectedPeers.length;
    notifyListeners();
  }

  void clearPeers() {
     _connectedPeers.clear();
     _connectedNodesCount = 0;
     notifyListeners();
  }

  Future<void> syncNodesWithBackend() async {
    try {
      final String base = AuthService.baseUrl;
      final response = await http.get(Uri.parse('$base/api/nodes'))
          .timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final List<dynamic> serverNodes = jsonDecode(response.body);
        for (var node in serverNodes) {
          if (node is Map) {
            final Map<String, dynamic> nodeMap = Map<String, dynamic>.from(node);
            final nodeId = nodeMap['id']?.toString() ?? '';
            if (nodeId.isEmpty) continue;
            
            await MeshDatabase.instance.upsertNode({
              'id': nodeId,
              'name': nodeMap['name']?.toString() ?? '',
              'lastSeen': (nodeMap['lastSeen'] is num) 
                  ? (nodeMap['lastSeen'] as num).toInt() 
                  : (int.tryParse(nodeMap['lastSeen']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch),
              'lat': (nodeMap['lat'] is num) ? (nodeMap['lat'] as num).toDouble() : null,
              'lng': (nodeMap['lng'] is num) ? (nodeMap['lng'] as num).toDouble() : null,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("API nodes sync failed: $e");
    }
  }

  Future<void> loadDiscoveredNodes() async {
    await syncNodesWithBackend();
    final results = await MeshDatabase.instance.getAllNodes();
    _discoveredNodes = List<Map<String, dynamic>>.from(results);
    notifyListeners();
  }

  Future<void> upsertDiscoveredNode(Map<String, dynamic> node) async {
    await MeshDatabase.instance.upsertNode(node);
    await loadDiscoveredNodes();
  }
}
