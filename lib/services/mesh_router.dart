import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'mesh_database.dart';
import 'mesh_network_manager.dart';
import '../providers/chat_provider.dart';
import '../providers/mesh_provider.dart';

class MeshRouter {
  static final MeshRouter instance = MeshRouter._init();
  MeshRouter._init();

  late ChatProvider _chatProvider;
  late MeshProvider _meshProvider;
  late String localDeviceId;
  Timer? _beaconTimer;
  
  // Basic Encryption setup
  final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final iv = encrypt.IV.fromUtf8('my16lengthsuper1'); // Fixed IV for basic P2P sync
  late encrypt.Encrypter encrypter;

  void init(String deviceId, ChatProvider chatProvider, MeshProvider meshProvider) {
    localDeviceId = deviceId;
    _chatProvider = chatProvider;
    _meshProvider = meshProvider;
    MeshNetworkManager.instance.onPayloadReceived = _onPayloadReceived;
    encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  // Incoming Payload Handler
  Future<void> _onPayloadReceived(String endpointId, Payload payload) async {
    try {
      if (payload.bytes == null || payload.type != PayloadType.BYTES) {
        debugPrint("Skipping non-bytes payload from $endpointId (type: ${payload.type})");
        return;
      }
      final String jsonStr = utf8.decode(payload.bytes!);
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      
      // Basic ACK handling: if message is an ACK, update status
      if (data['type'] == 'ACK') {
        final ackMsgId = data['messageId'];
        await MeshDatabase.instance.updateMessageStatus(ackMsgId, 'Delivered');
        await _chatProvider.loadMessages(_chatProvider.currentPeerId);
        return;
      }
      
      // ----------- MESH GPS BEACON ROUTING -----------
      if (data['type'] == 'GPS_BEACON') {
        final String senderId = data['senderId'];
        final int timestamp = data['timestamp'];
        final double lat = data['lat'];
        final double lng = data['lng'];
        final int ttl = data['ttl'] ?? 0;
        final int hops = data['hops'] ?? 0;

        // Deduplicate using timestamp
        final allNodes = await MeshDatabase.instance.getAllNodes();
        final existingNode = allNodes.firstWhere((node) => node['id'] == senderId, orElse: () => {});
        if (existingNode.isNotEmpty) {
          final int lastSeen = existingNode['lastSeen'] ?? 0;
          if (lastSeen >= timestamp) {
            // Already received this or a newer update. Discard it.
            return;
          }
        }

        // Upsert the peer's coordinate beacon
        await MeshDatabase.instance.upsertNode({
          'id': senderId,
          'name': data['name'] ?? senderId.substring(0, 8),
          'lastSeen': timestamp,
          'lat': lat,
          'lng': lng,
        });

        // Trigger dynamic provider refresh
        await _meshProvider.loadDiscoveredNodes();

        // Forward multi-hop across the P2P cluster if TTL allows
        if (ttl > 0 && senderId != localDeviceId) {
          data['ttl'] = ttl - 1;
          data['hops'] = hops + 1;
          final updatedBytes = utf8.encode(jsonEncode(data));
          final forwardPayload = Payload(
            id: DateTime.now().millisecondsSinceEpoch,
            bytes: Uint8List.fromList(updatedBytes),
            type: PayloadType.BYTES,
          );
          await MeshNetworkManager.instance.broadcastPayload(forwardPayload, excludeEndpoint: endpointId);
        }
        return;
      }
      // -----------------------------------------------
      
      final String messageId = data['messageId'];
      
      // 1. Check if seen before
      final bool seen = await MeshDatabase.instance.messageExists(messageId);
      if (seen) return; // Drop it
      
      // 2. Decrypt Content
      String decryptedContent = data['content'];
      try {
         decryptedContent = encrypter.decrypt64(data['content'], iv: iv);
      } catch (e) {
         debugPrint("Decryption failed: $e \nRaw content: ${data['content']}");
         decryptedContent = "ENCRYPTED_MESSAGE";
      }
      
      // 3. Not seen: Save it
      data['status'] = 'Received';
      data['content'] = decryptedContent; // Save decrypted locally
      await MeshDatabase.instance.insertMessage(data);
      
      // 4. Update Chat Provider so UI updates if it's the receiver or broadcast
      _chatProvider.addMessageLocally(data);

      final String receiverId = data['receiverId'];
      final int ttl = data['ttl'] ?? 0;

      // --- GATEWAY NODE LOGIC FOR INCOMING MESH MESSAGES ---
      if (receiverId == 'AUTHORITIES') {
        bool hasInternet = false;
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          hasInternet = !connectivityResult.contains(ConnectivityResult.none);
        } catch (e) {
          debugPrint("Connectivity check failed: $e");
        }

        if (hasInternet) {
          try {
             final response = await http.post(
               Uri.parse('https://jsonplaceholder.typicode.com/posts'),
               body: jsonEncode({'payload': decryptedContent, 'sender': data['senderId']}),
               headers: {'Content-Type': 'application/json'},
             );
             if (response.statusCode == 201 || response.statusCode == 200) {
                debugPrint("GATEWAY SUCCESS: Relayed node message to Authorities via Internet!");
                await MeshDatabase.instance.updateMessageStatus(messageId, 'Gateway Delivered');
                return; // Delivered to authorities! Stop propagating on the limited mesh network.
             }
          } catch(e) {
             debugPrint("Gateway HTTP forward failed: $e");
          }
        }
      }
      // -----------------------------------------------------

      // 5. If memory is me, send ACK back and don't forward payload.
      if (receiverId == localDeviceId) {
        _sendAck(data['senderId'], messageId);
        return;
      }
      
      // 6. If BROADCAST or not me: Forward it if TTL > 0
      if (ttl > 0 && data['senderId'] != localDeviceId) {
         // Re-encrypt before forwarding
         data['content'] = encrypter.encrypt(decryptedContent, iv: iv).base64;
         data['ttl'] = ttl - 1;
         data['hops'] = (data['hops'] as int? ?? 0) + 1; // Track hop count
         data['status'] = 'Relayed';
         await MeshDatabase.instance.updateMessageStatus(messageId, 'Relayed');
         final updatedBytes = utf8.encode(jsonEncode(data));
         final forwardPayload = Payload(id: DateTime.now().millisecondsSinceEpoch, bytes: Uint8List.fromList(updatedBytes), type: PayloadType.BYTES);
         
         // Broadcast to all peers except the sender
         await MeshNetworkManager.instance.broadcastPayload(forwardPayload, excludeEndpoint: endpointId);
      }
    } catch (e) {
      debugPrint("Error routing payload: $e");
    }
  }

  Future<void> _sendAck(String originalSender, String messageId) async {
     final ackData = {
       'type': 'ACK',
       'messageId': messageId,
       'senderId': localDeviceId,
       'receiverId': originalSender,
       'timestamp': DateTime.now().millisecondsSinceEpoch,
     };
     final bytes = utf8.encode(jsonEncode(ackData));
     final payload = Payload(id: DateTime.now().millisecondsSinceEpoch, bytes: Uint8List.fromList(bytes));
     await MeshNetworkManager.instance.broadcastPayload(payload);
  }

  // Send a new message
  Future<void> sendMessage(String receiverId, String content, {bool isBroadcast = false, int initialTtl = 5}) async {
    final messageId = const Uuid().v4();
    final encryptedContent = encrypter.encrypt(content, iv: iv).base64;
    
    final messageData = {
      'messageId': messageId,
      'senderId': localDeviceId,
      'receiverId': receiverId,
      'content': encryptedContent,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'ttl': initialTtl,
      'hops': 0, // Starts at 0; incremented by each relay node
      'status': 'Sent',
    };

    // --- GATEWAY NODE LOGIC FOR LOCAL MESSAGES ---
    if (receiverId == 'AUTHORITIES') {
      bool hasInternet = false;
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        hasInternet = !connectivityResult.contains(ConnectivityResult.none);
      } catch (e) {
        debugPrint("Connectivity check failed: $e");
      }
      
      if (hasInternet) {
         try {
           await http.post(
             Uri.parse('https://jsonplaceholder.typicode.com/posts'),
             body: jsonEncode({'payload': content, 'sender': localDeviceId}),
             headers: {'Content-Type': 'application/json'},
           );
           messageData['status'] = 'Gateway Delivered';
           debugPrint("GATEWAY SUCCESS: Local authorities alert sent directly to internet.");
         } catch (e) {
            debugPrint("HTTP post failed, falling back to offline mesh: $e");
         }
      }
    }
    // ---------------------------------------------

    // Save decrypted to local DB & UI
    final localData = Map<String, dynamic>.from(messageData);
    localData['content'] = content;
    await MeshDatabase.instance.insertMessage(localData);
    _chatProvider.addMessageLocally(localData);

    // Send encrypted payload
    final bytes = utf8.encode(jsonEncode(messageData));
    final payload = Payload(id: DateTime.now().millisecondsSinceEpoch, bytes: Uint8List.fromList(bytes), type: PayloadType.BYTES);
    await MeshNetworkManager.instance.broadcastPayload(payload);
  }

  // Periodic GPS beacon active methods
  void startBeaconBroadcasting() {
    _beaconTimer?.cancel();
    _beaconTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await broadcastLocationBeacon();
    });
    Future.delayed(const Duration(seconds: 2), () {
      broadcastLocationBeacon();
    });
  }

  void stopBeaconBroadcasting() {
    _beaconTimer?.cancel();
    _beaconTimer = null;
  }

  Future<void> broadcastLocationBeacon() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services disabled, skipping beacon.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("Location permissions denied, skipping beacon.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("Location permissions denied forever, skipping beacon.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final deviceName = await _getDeviceName();

      double lat = position.latitude;
      double lng = position.longitude;
      if (kIsWeb) {
        // Add a small stable offset (approx 30-100 meters) so they don't overlap in web tests
        final randomOffsetLat = (localDeviceId.hashCode % 100 - 50) * 0.00005;
        final randomOffsetLng = (localDeviceId.hashCode % 100 - 50) * 0.00005;
        lat += randomOffsetLat;
        lng += randomOffsetLng;
      }

      final beaconData = {
        'type': 'GPS_BEACON',
        'messageId': 'beacon-$localDeviceId-${DateTime.now().millisecondsSinceEpoch}',
        'senderId': localDeviceId,
        'name': deviceName,
        'receiverId': 'BROADCAST',
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': 5,
        'hops': 0,
      };

      // Upsert self location node in local DB
      await MeshDatabase.instance.upsertNode({
        'id': localDeviceId,
        'name': 'Self ($deviceName)',
        'lastSeen': beaconData['timestamp'],
        'lat': position.latitude,
        'lng': position.longitude,
      });
      await _meshProvider.loadDiscoveredNodes();

      final bytes = utf8.encode(jsonEncode(beaconData));
      final payload = Payload(
        id: DateTime.now().millisecondsSinceEpoch,
        bytes: Uint8List.fromList(bytes),
        type: PayloadType.BYTES,
      );

      await MeshNetworkManager.instance.broadcastPayload(payload);
      debugPrint("GPS Beacon broadcasted successfully: Lat: ${position.latitude}, Lng: ${position.longitude}");
    } catch (e) {
      debugPrint("Error broadcasting location beacon: $e");
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webBrowserInfo = await deviceInfo.webBrowserInfo;
        return webBrowserInfo.browserName.name;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      debugPrint("Failed to fetch device model name: $e");
    }
    return localDeviceId.substring(0, 8);
  }
}
