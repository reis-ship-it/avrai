/// Discovered Devices Widget
/// 
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
/// 
/// Reusable widget for displaying discovered devices with connection options.
/// Can be embedded in different pages or contexts.
/// 
/// Features:
/// - List view of discovered devices
/// - Device info display (name, type, proximity, signal strength)
/// - Connection initiation buttons
/// - Real-time updates
/// - Privacy-preserving personality indicators
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:get_it/get_it.dart';

/// Widget displaying discovered devices with connection options
class DiscoveredDevicesWidget extends StatefulWidget {
  final List<DiscoveredDevice> devices;
  final VoidCallback? onRefresh;
  final Function(DiscoveredDevice)? onDeviceTap;
  final bool showConnectionButton;
  
  const DiscoveredDevicesWidget({
    super.key,
    required this.devices,
    this.onRefresh,
    this.onDeviceTap,
    this.showConnectionButton = true,
  });
  
  @override
  State<DiscoveredDevicesWidget> createState() => _DiscoveredDevicesWidgetState();
}

class _DiscoveredDevicesWidgetState extends State<DiscoveredDevicesWidget> {
  final Map<String, bool> _connectingDevices = {};
  VibeConnectionOrchestrator? _orchestrator;
  
  @override
  void initState() {
    super.initState();
    _initializeOrchestrator();
  }
  
  void _initializeOrchestrator() {
    try {
      _orchestrator = GetIt.instance<VibeConnectionOrchestrator>();
    } catch (e) {
      developer.log(
        'Connection orchestrator not available',
        name: 'DiscoveredDevicesWidget',
        error: e,
      );
    }
  }
  
  Future<void> _connectToDevice(DiscoveredDevice device) async {
    setState(() {
      _connectingDevices[device.deviceId] = true;
    });

    // Even if orchestrator isn't available (eg. some widget-test contexts),
    // show immediate feedback and then clear the state.
    if (_orchestrator == null) {
      _showSnackBar('Connection service unavailable');
      // Keep "Connecting..." visible for at least a beat.
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        setState(() {
          _connectingDevices[device.deviceId] = false;
        });
      }
      return;
    }
    
    try {
      // Connection logic will be handled by orchestrator
      // For now, show feedback to user
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        _showSnackBar('Connecting to ${device.deviceName}...');
        setState(() {
          _connectingDevices[device.deviceId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Connection failed: $e');
        setState(() {
          _connectingDevices[device.deviceId] = false;
        });
      }
    }
  }
  
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.devices.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
      },
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: widget.devices.length,
        itemBuilder: (context, index) {
          return _buildDeviceCard(widget.devices[index]);
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_other,
              size: 64,
              color: AppColors.grey300,
            ),
            SizedBox(height: 16),
            Text(
              'No devices discovered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Make sure discovery is enabled and nearby devices are active',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceCard(DiscoveredDevice device) {
    final proximityScore = device.proximityScore;
    final proximityColor = _getProximityColor(proximityScore);
    final proximityLabel = _getProximityLabel(proximityScore);
    final isConnecting = _connectingDevices[device.deviceId] ?? false;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: widget.onDeviceTap != null 
            ? () => widget.onDeviceTap!(device)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildDeviceIcon(device),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildDeviceType(device.type),
                      ],
                    ),
                  ),
                  if (device.personalityData != null)
                    _buildPersonalityBadge(),
                ],
              ),
              const SizedBox(height: 12),
              _buildDeviceMetrics(device, proximityLabel, proximityColor),
              if (widget.showConnectionButton) ...[
                const SizedBox(height: 12),
                _buildConnectionButton(device, isConnecting),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeviceIcon(DiscoveredDevice device) {
    final proximityColor = _getProximityColor(device.proximityScore);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: proximityColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getDeviceIconData(device.type),
        color: proximityColor,
        size: 32,
      ),
    );
  }
  
  Widget _buildDeviceType(DeviceType type) {
    String typeLabel;
    switch (type) {
      case DeviceType.wifi:
        typeLabel = 'WiFi';
        break;
      case DeviceType.bluetooth:
        typeLabel = 'Bluetooth';
        break;
      case DeviceType.wifiDirect:
        typeLabel = 'WiFi Direct';
        break;
      case DeviceType.multpeerConnectivity:
        typeLabel = 'Multipeer';
        break;
      case DeviceType.webrtc:
        typeLabel = 'WebRTC';
        break;
    }
    
    return Text(
      typeLabel,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
  
  Widget _buildPersonalityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.electricGreen,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: AppColors.white,
          ),
          SizedBox(width: 6),
          Text(
            'AI Enabled',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceMetrics(
    DiscoveredDevice device,
    String proximityLabel,
    Color proximityColor,
  ) {
    return Row(
      children: [
        _buildMetricChip(
          Icons.location_on,
          proximityLabel,
          proximityColor,
        ),
        const SizedBox(width: 12),
        if (device.signalStrength != null)
          _buildMetricChip(
            Icons.signal_cellular_alt,
            '${device.signalStrength} dBm',
            AppColors.textSecondary,
          ),
      ],
    );
  }
  
  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionButton(DiscoveredDevice device, bool isConnecting) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isConnecting ? null : () => _connectToDevice(device),
        icon: isConnecting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : const Icon(Icons.link),
        label: Text(isConnecting ? 'Connecting...' : 'Connect'),
        style: ElevatedButton.styleFrom(
          backgroundColor: device.personalityData != null
              ? AppColors.electricGreen
              : AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
  
  IconData _getDeviceIconData(DeviceType type) {
    switch (type) {
      case DeviceType.wifi:
        return Icons.wifi;
      case DeviceType.bluetooth:
        return Icons.bluetooth;
      case DeviceType.wifiDirect:
        return Icons.wifi_tethering;
      case DeviceType.multpeerConnectivity:
        return Icons.devices;
      case DeviceType.webrtc:
        return Icons.web;
    }
  }
  
  Color _getProximityColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
  
  String _getProximityLabel(double score) {
    if (score >= 0.7) return 'Very Close';
    if (score >= 0.4) return 'Nearby';
    return 'Far';
  }
}
