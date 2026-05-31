import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import 'package:uuid/uuid.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'providers/mesh_provider.dart';
import 'providers/chat_provider.dart';
import 'services/mesh_network_manager.dart';
import 'services/mesh_router.dart';
import 'services/hardware_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Initialize hardware and permissions for mesh networking
    final hardwareService = HardwareService();
    bool allPerms = await hardwareService.requestAllPermissions();
    debugPrint("Permissions all granted: $allPerms");
    await hardwareService.initializeBluetooth();
    bool locInit = await hardwareService.initializeLocation();
    debugPrint("Location initialized: $locInit");
  }
  
  String deviceId;
  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    final idFile = File('${dir.path}/device_id.txt');
    if (await idFile.exists()) {
      deviceId = await idFile.readAsString();
    } else {
      deviceId = 'node-${const Uuid().v4().substring(0, 8)}';
      await idFile.writeAsString(deviceId);
    }
  } else {
    // Generate a new random device ID for every tab session on Web for testing
    deviceId = 'web-${const Uuid().v4().substring(0, 8)}';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MeshProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider(deviceId)), 
      ],
      child: ResQNetApp(deviceId: deviceId),
    ),
  );
}

class ResQNetApp extends StatefulWidget {
  final String deviceId;
  const ResQNetApp({super.key, required this.deviceId});

  @override
  State<ResQNetApp> createState() => _ResQNetAppState();
}

class _ResQNetAppState extends State<ResQNetApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _initMesh();
    });
  }
  
  Future<void> _initMesh() async {
    final meshProvider = context.read<MeshProvider>();
    final chatProvider = context.read<ChatProvider>();
    
    final deviceId = widget.deviceId;
    
    await MeshNetworkManager.instance.init(deviceId, meshProvider);
    MeshRouter.instance.init(deviceId, chatProvider, meshProvider);
    
    await meshProvider.loadDiscoveredNodes();
    await MeshNetworkManager.instance.startMesh();
    MeshRouter.instance.startBeaconBroadcasting();
  }

  @override
  void dispose() {
    MeshRouter.instance.stopBeaconBroadcasting();
    MeshNetworkManager.instance.stopMesh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tacticalTheme,
      home: const SplashScreen(),
    );
  }
}
