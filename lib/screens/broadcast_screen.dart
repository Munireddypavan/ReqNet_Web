import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';
import '../services/mesh_router.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final TextEditingController _msgController = TextEditingController();
  bool _isBroadcasting = false;

  void _triggerSos() async {
    final msg = _msgController.text.isNotEmpty ? _msgController.text : "SOS EMERGENCY BROADCAST";
    setState(() => _isBroadcasting = true);
    
    // Broadcast with Max TTL (10 hops)
    await MeshRouter.instance.sendMessage(
      'BROADCAST', 
      "*** SOS ***\n$msg", 
      isBroadcast: true, 
      initialTtl: 10, 
    );

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('SOS Broadcast Sent across Mesh!'), backgroundColor: AppTheme.primary)
       );
    }
    
    setState(() => _isBroadcasting = false);
    _msgController.clear();
  }

  void _triggerAuthorities() async {
    setState(() => _isBroadcasting = true);
    
    String locationStr = "Location Unknown";
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      locationStr = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    } catch(e) {
      debugPrint("Could not get location: $e");
    }

    final msg = _msgController.text.isNotEmpty ? _msgController.text : "CRITICAL POLICE/MEDICAL EMERGENCY";
    
    await MeshRouter.instance.sendMessage(
      'AUTHORITIES', 
      "*** DISPATCH EMERGENCY ***\n$msg\n$locationStr", 
      isBroadcast: true, 
      initialTtl: 10, 
    );

    if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Authorities alert dispatched into Mesh!'), backgroundColor: AppTheme.secondary)
       );
    }
    
    setState(() => _isBroadcasting = false);
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('EMERGENCY COMMS', style: TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                AnimatedContainer(duration: const Duration(milliseconds: 300), width: 8, height: 8, decoration: BoxDecoration(color: _isBroadcasting ? Colors.red : AppTheme.primary, shape: BoxShape.circle)),
              ],
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Broadcast',
              style: TextStyle(fontFamily: 'Inter', fontSize: 36, fontWeight: FontWeight.w300, letterSpacing: -1.0),
            ),
            
            const SizedBox(height: 32),
            TextField(
              controller: _msgController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w400, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter urgent message...',
                hintStyle: const TextStyle(color: AppTheme.outline, fontWeight: FontWeight.w300),
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.surfaceContainerHighest),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Range', Icons.sensors, 'Max', 'Hop')),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Priority', Icons.warning_amber, 'First', 'Lvl')),
              ],
            ),
            
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  onLongPress: _triggerSos,
                  icon: Icons.emergency,
                  label: _isBroadcasting ? 'Sending...' : 'GLOBAL SOS',
                  color: Colors.redAccent,
                ),
                _buildActionButton(
                  onLongPress: _triggerAuthorities,
                  icon: Icons.local_police_outlined,
                  label: _isBroadcasting ? 'Sending...' : 'AUTHORITIES',
                  color: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Hold buttons for 3s to initiate broadcast', 
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400, color: AppTheme.outline)
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required VoidCallback onLongPress, required IconData icon, required String label, required Color color}) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120, height: 120,
        decoration: BoxDecoration(
          color: _isBroadcasting ? color.withValues(alpha: 0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: _isBroadcasting ? color : AppTheme.surfaceContainerHighest, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _isBroadcasting ? color : AppTheme.onSurface, size: 32),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: _isBroadcasting ? color : AppTheme.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, IconData iconData, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconData, color: AppTheme.outline, size: 16),
            const SizedBox(width: 8),
            Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.outline, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: AppTheme.onSurface)),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.outline)),
          ],
        ),
      ],
    );
  }
}
