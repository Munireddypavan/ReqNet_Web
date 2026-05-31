import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

class HardwareService {
  static final HardwareService _instance = HardwareService._internal();

  factory HardwareService() {
    return _instance;
  }

  HardwareService._internal();

  /// Requests all necessary permissions for Bluetooth, Wi-Fi Direct, and Location
  Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ].request();

    bool allGranted = true;
    for (var entry in statuses.entries) {
      debugPrint("Permission ${entry.key} status: ${entry.value}");
      if (!entry.value.isGranted) {
        allGranted = false;
      }
    }
    return allGranted;
  }

  /// Initializes the Bluetooth hardware
  Future<void> initializeBluetooth() async {
    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("Bluetooth not supported by this device");
      return;
    }
    
    // Turn on bluetooth if possible (Android only)
    try {
      if(await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      debugPrint("Error turning on Bluetooth: $e");
    }
  }

  /// Checks if Location Services are enabled and requests permission
  Future<bool> initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    } 

    return true;
  }
}
