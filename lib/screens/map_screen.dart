import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme.dart';
import '../providers/mesh_provider.dart';
import '../services/mesh_router.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  bool _isLoading = true;
  String _errorMessage = '';
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MeshProvider>().loadDiscoveredNodes();
      }
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Location services are disabled.';
          _isLoading = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
      }
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
    }
  }

  List<Marker> _buildMapMarkers(MeshProvider meshProvider) {
    final List<Marker> markers = [];

    // 1. Add current self location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 48,
          height: 48,
          child: Tooltip(
            message: "My Location",
            child: Container(
              alignment: Alignment.center,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Add other discovered peers
    for (var node in meshProvider.discoveredNodes) {
      final double? lat = node['lat'];
      final double? lng = node['lng'];
      final String id = node['id'] ?? '';
      final String name = node['name'] ?? 'Unknown Node';

      if (lat == null || lng == null || id.isEmpty) continue;
      
      // Skip self in discovery peers to keep specific self styling
      final bool isSelf = id == MeshRouter.instance.localDeviceId;
      if (isSelf) continue;

      final peerPos = LatLng(lat, lng);
      
      markers.add(
        Marker(
          point: peerPos,
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => _showNodeInspector(node),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.outline.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: Text(
                    name.length > 8 ? name.substring(0, 8) : name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.secondaryContainer, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_pin_circle_rounded,
                      size: 14,
                      color: AppTheme.secondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showNodeInspector(Map<String, dynamic> node) {
    final String name = node['name'] ?? 'Unknown Node';
    final String id = node['id'] ?? 'N/A';
    final double lat = node['lat'] ?? 0.0;
    final double lng = node['lng'] ?? 0.0;
    final int timestamp = node['lastSeen'] ?? 0;
    
    String distanceStr = 'Unknown';
    if (_currentPosition != null) {
      final double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      if (distanceInMeters >= 1000) {
        distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
      } else {
        distanceStr = '${distanceInMeters.toStringAsFixed(0)} m';
      }
    }

    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(dt);
    String lastSeenStr;
    if (diff.inSeconds < 15) {
      lastSeenStr = 'Active just now';
    } else if (diff.inMinutes < 1) {
      lastSeenStr = 'Active ${diff.inSeconds}s ago';
    } else if (diff.inHours < 1) {
      lastSeenStr = 'Active ${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      lastSeenStr = 'Active ${diff.inHours}h ago';
    } else {
      lastSeenStr = 'Active ${diff.inDays}d ago';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.surfaceContainerHighest, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lastSeenStr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'NODE ID: ${id.toUpperCase()}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppTheme.outline.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInspectorStat('EST. DISTANCE', distanceStr, Icons.sensors),
                  ),
                  Expanded(
                    child: _buildInspectorStat('COORDINATES', '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', Icons.location_on_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mapController.move(LatLng(lat, lng), 16.5);
                      },
                      icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                      label: const Text('FOCUS NODE'),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        foregroundColor: AppTheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Starting chat connection request with $name...'),
                            backgroundColor: AppTheme.primary,
                          ),
                        );
                      },
                      icon: const Icon(Icons.forum_rounded, size: 16, color: AppTheme.background),
                      label: const Text('SECURE CHAT', style: TextStyle(color: AppTheme.background, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspectorStat(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.outline, size: 12),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.outline,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final meshProvider = context.watch<MeshProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.redAccent, fontFamily: 'Inter', fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition!,
                          initialZoom: 16.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.resqnet.app',
                          ),
                          MarkerLayer(
                            markers: _buildMapMarkers(meshProvider),
                          ),
                        ],
                      ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHighest.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1), 
                        blurRadius: 10, 
                        offset: const Offset(0, 4)
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_tethering, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${meshProvider.connectedNodesCount} NODES ACTIVE',
                        style: const TextStyle(
                          fontFamily: 'Inter', 
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(_currentPosition!, 16.0);
          }
        },
        backgroundColor: AppTheme.primaryContainer,
        foregroundColor: AppTheme.onPrimaryContainer,
        elevation: 4,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
