import 'package:flutter/foundation.dart';
import '../services/mesh_database.dart';

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

  Future<void> loadDiscoveredNodes() async {
    final results = await MeshDatabase.instance.getAllNodes();
    _discoveredNodes = List<Map<String, dynamic>>.from(results);
    notifyListeners();
  }

  Future<void> upsertDiscoveredNode(Map<String, dynamic> node) async {
    await MeshDatabase.instance.upsertNode(node);
    await loadDiscoveredNodes();
  }
}
