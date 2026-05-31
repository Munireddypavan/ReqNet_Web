import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../providers/mesh_provider.dart';
import 'mesh_router.dart';

class MeshNetworkManager {
  static final MeshNetworkManager instance = MeshNetworkManager._init();
  MeshNetworkManager._init();

  late String localEndpointName;
  late MeshProvider _meshProvider;
  final Strategy strategy = Strategy.P2P_CLUSTER;

  Timer? _scanTimer;
  Timer? _webMockTimer;
  int _lastMessageCount = 0;
  Map<String, ConnectionInfo> endpointMap = {};
  
  // Callback for when a payload is received. The router will set this.
  Function(String endpointId, Payload payload)? onPayloadReceived;

  Future<void> init(String userName, MeshProvider provider) async {
    localEndpointName = userName;
    _meshProvider = provider;
  }

  Future<void> startMesh() async {
    if (kIsWeb) {
      _startWebMockMesh();
      return;
    }
    await startAdvertising();
    await startDiscovery();
    _startAutoScan();
  }

  void stopMesh() {
    _scanTimer?.cancel();
    _webMockTimer?.cancel();
    _meshProvider.clearPeers();
    endpointMap.clear();

    if (kIsWeb) return;
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    Nearby().stopAllEndpoints();
  }

  void _startWebMockMesh() {
    debugPrint("Starting Web Mock Mesh Network");
    _webMockTimer?.cancel();
    _meshProvider.addPeer('web-peer', 'Web Peer');
    endpointMap['web-peer'] = ConnectionInfo('web-peer', '', false);
    
    _webMockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
       final prefs = await SharedPreferences.getInstance();
       await prefs.reload();
       final messages = prefs.getStringList('web_mock_messages') ?? [];
       if (messages.length > _lastMessageCount) {
         for (int i = _lastMessageCount; i < messages.length; i++) {
           try {
             final decoded = jsonDecode(messages[i]);
             if (decoded['senderId'] == localEndpointName) continue;

             final bytes = utf8.encode(messages[i]);
             if (onPayloadReceived != null) {
               onPayloadReceived!('web-peer', Payload(
                 bytes: Uint8List.fromList(bytes),
                 id: DateTime.now().millisecondsSinceEpoch,
                 type: PayloadType.BYTES,
               ));
             }
           } catch(e) {
             // ignore: empty_catches
           }
         }
         _lastMessageCount = messages.length;
       }
    });
  }

  Future<void> startAdvertising() async {
    if (kIsWeb) return;
    try {
      bool a = await Nearby().startAdvertising(
        localEndpointName,
        strategy,
        onConnectionInitiated: (String id, ConnectionInfo info) {
          // Auto accept connection
          endpointMap[id] = info;
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (endpointId, payload) {
              // Use closure so we always call the LATEST registered callback,
              // avoiding a race where onPayloadReceived is still null at connect time.
              onPayloadReceived?.call(endpointId, payload);
            },
            onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
          );
        },
        onConnectionResult: (String id, Status status) {
          if (status == Status.CONNECTED) {
            final info = endpointMap[id];
            if (info != null) {
              _meshProvider.addPeer(id, info.endpointName);
              // Immediately broadcast GPS coordinates so the peer sees us on the map
              MeshRouter.instance.broadcastLocationBeacon();
            }
          } else if (status == Status.ERROR || status == Status.REJECTED) {
             // Only remove if we haven't successfully connected.
             // A duplicate connection attempt might fire ERROR while the primary succeeds.
             bool isConnected = _meshProvider.connectedPeers.any((p) => p['id'] == id);
             if (!isConnected) {
               endpointMap.remove(id);
             }
          }
        },
        onDisconnected: (String id) {
          _meshProvider.removePeer(id);
          endpointMap.remove(id);
        },
      );
      debugPrint("Advertising started: $a");
    } catch (e) {
      debugPrint("Error starting advertising: $e");
    }
  }

  Future<void> startDiscovery() async {
    if (kIsWeb) return;
    try {
      bool a = await Nearby().startDiscovery(
        localEndpointName,
        strategy,
        onEndpointFound: (String id, String userName, String serviceId) {
          // Skip if already connected to this endpoint
          if (endpointMap.containsKey(id)) return;
          // Automatically request connection (guard against race conditions)
          try {
            Nearby().requestConnection(
              localEndpointName,
              id,
              onConnectionInitiated: (String id, ConnectionInfo info) {
                endpointMap[id] = info;
                Nearby().acceptConnection(
                  id,
                  onPayLoadRecieved: (endpointId, payload) {
                    // Use closure so we always call the LATEST registered callback.
                    onPayloadReceived?.call(endpointId, payload);
                  },
                  onPayloadTransferUpdate: (endpointId, payloadTransferUpdate) {},
                );
              },
              onConnectionResult: (String id, Status status) {
                if (status == Status.CONNECTED) {
                  final info = endpointMap[id];
                  if (info != null) {
                    _meshProvider.addPeer(id, info.endpointName);
                    // Immediately broadcast GPS coordinates so the peer sees us on the map
                    MeshRouter.instance.broadcastLocationBeacon();
                  }
                } else if (status == Status.ERROR || status == Status.REJECTED) {
                   bool isConnected = _meshProvider.connectedPeers.any((p) => p['id'] == id);
                   if (!isConnected) {
                     endpointMap.remove(id);
                   }
                }
              },
              onDisconnected: (String id) {
                _meshProvider.removePeer(id);
                endpointMap.remove(id);
              },
            );
          } catch (e) {
            // Silently ignore STATUS_ALREADY_CONNECTED_TO_ENDPOINT (8003) and similar
            debugPrint("requestConnection skipped for $id: $e");
          }
        },
        onEndpointLost: (String? id) {
           debugPrint("Endpoint lost: $id");
        },
      );
      debugPrint("Discovery started: $a");
    } catch (e) {
      debugPrint("Error starting discovery: $e");
    }
  }

  void _startAutoScan() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
       debugPrint("Auto-scan: restarting discovery...");
       await Nearby().stopDiscovery();
       await Future.delayed(const Duration(seconds: 1));
       await startDiscovery();
    });
  }

  Future<void> sendPayload(String receiverId, Payload payload) async {
     if (kIsWeb) {
       await _sendWebMockPayload(payload);
       return;
     }
     try {
       await Nearby().sendBytesPayload(receiverId, payload.bytes!);
     } catch (e) {
       debugPrint("Error sending payload to $receiverId: $e");
     }
  }

  Future<void> broadcastPayload(Payload payload, {String? excludeEndpoint}) async {
     if (kIsWeb) {
       await _sendWebMockPayload(payload);
       return;
     }
     for (String peerId in endpointMap.keys) {
       if (peerId == excludeEndpoint) continue; // Don't echo back to sender
       await sendPayload(peerId, payload);
     }
  }

  Future<void> _sendWebMockPayload(Payload payload) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.reload();
     final messages = prefs.getStringList('web_mock_messages') ?? [];
     String msgStr = utf8.decode(payload.bytes!);
     messages.add(msgStr);
     await prefs.setStringList('web_mock_messages', messages);
  }
}
