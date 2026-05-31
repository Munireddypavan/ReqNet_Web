import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/mesh_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/chat_provider.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final meshProvider = context.watch<MeshProvider>();
    final chatProvider = context.watch<ChatProvider>();
    
    final int totalPackets = chatProvider.messages.length;
    final int relayedPackets = chatProvider.messages.where((m) => m['status'] == 'Relayed').length;
    int failedMessages = chatProvider.messages.where((m) => m['status'] == 'Error' || m['status'] == 'Failed').length;
    
    int healthScore = 100;
    if (meshProvider.connectedNodesCount == 0) {
      healthScore -= 15;
    }
    if (failedMessages > 0) {
      healthScore -= (failedMessages * 2); 
    }
    if (healthScore < 0) healthScore = 0;
    
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          const Text('LOCAL NODE IDENTIFIER', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _getDeviceName(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? 'LOADING...',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1.0, color: AppTheme.onSurface),
              );
            },
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(child: _buildStat('CONNECTED', '${meshProvider.connectedNodesCount}')),
              Expanded(child: _buildStat('PACKETS', '$totalPackets')),
              Expanded(child: _buildStat('ROUTED', '$relayedPackets')),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.surfaceContainerHighest),
          const SizedBox(height: 32),
          
          const Text('SYSTEM INTEGRITY', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$healthScore%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: healthScore > 80 ? AppTheme.primary : AppTheme.error)),
              const SizedBox(width: 12),
              Icon(healthScore > 80 ? Icons.check_circle_outline : Icons.error_outline, color: healthScore > 80 ? AppTheme.primary : AppTheme.error, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Encryption keys rotated automatically. Mesh protocols adapting to network parameters.', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, height: 1.5)),
          
          const SizedBox(height: 32),
          const Divider(height: 1, thickness: 0.5, color: AppTheme.surfaceContainerHighest),
          const SizedBox(height: 32),
          
          const Text('MESH PARTICIPATION', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildToggleRow('Bluetooth LE', Icons.bluetooth, meshProvider),
          const SizedBox(height: 12),
          _buildToggleRow('Wi-Fi Direct', Icons.wifi_tethering, meshProvider),
          const SizedBox(height: 12),
          _buildToggleRow('LoRa Relay', Icons.cell_tower, meshProvider),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: AppTheme.onSurface)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.outline, letterSpacing: 1.0)),
      ],
    );
  }

  Widget _buildToggleRow(String title, IconData icon, MeshProvider meshProvider) {
    final isOn = meshProvider.isProtocolActive(title);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isOn ? AppTheme.primary : AppTheme.outline, size: 20),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: isOn ? FontWeight.w600 : FontWeight.w400, color: isOn ? AppTheme.onSurface : AppTheme.onSurfaceVariant))),
          Switch(
            value: isOn,
            onChanged: (v) {
              meshProvider.toggleProtocol(title, v);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.surfaceContainerHighest,
            inactiveThumbColor: AppTheme.outline,
          ),
        ],
      ),
    );
  }

  Future<String> _getDeviceName() async {
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
    return 'Unknown Device';
  }
}
