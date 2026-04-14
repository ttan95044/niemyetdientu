import 'package:flutter/material.dart';
import 'package:niemyetdientu/service/log_service.dart';

/// Helper class để detect, log, và apply resolution-specific offset corrections
class ResolutionHelper {
  /// Singleton instance
  static final ResolutionHelper _instance = ResolutionHelper._internal();

  factory ResolutionHelper() {
    return _instance;
  }

  ResolutionHelper._internal();

  /// Cache các thông tin resolution
  late MediaQueryData _mediaQueryData;
  late double _deviceWidth;
  late double _deviceHeight;
  late double _devicePixelRatio;
  late String _deviceProfile;

  /// Resolution-specific offset corrections (tuning values per device)
  /// Key: deviceProfile (e.g., "1080x1920", "2160x3840")
  /// Value: {offsetX, offsetY}
  final Map<String, Map<String, double>> _resolutionOffsets = {
    // Example profiles - customize based on your devices
    "1080x1920": {"offsetX": -10.0, "offsetY": -17.0}, // Default
    "2160x3840": {"offsetX": -20.0, "offsetY": -34.0}, // Higher resolution
    "720x1280": {"offsetX": -5.0, "offsetY": -8.0}, // Lower resolution
  };

  /// Initialize with context - call this once at app startup
  void initialize(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    _deviceWidth = _mediaQueryData.size.width;
    _deviceHeight = _mediaQueryData.size.height;
    _devicePixelRatio = _mediaQueryData.devicePixelRatio;

    // Calculate theoretical physical resolution
    final physicalWidth = _deviceWidth * _devicePixelRatio;
    final physicalHeight = _deviceHeight * _devicePixelRatio;
    _deviceProfile = "${physicalWidth.toInt()}x${physicalHeight.toInt()}";

    // Get current offset corrections for this device
    final offsets = getOffsetCorrections();
    final currentOffsetX = offsets['offsetX'] ?? 0.0;
    final currentOffsetY = offsets['offsetY'] ?? 0.0;

    // ===== DEVICE INITIALIZATION LOG (merged all device info) =====
    LogService.send({
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
      'action': 'device_initialized',
      'device_profile': _deviceProfile,
      'logical_width': _deviceWidth,
      'logical_height': _deviceHeight,
      'physical_width': physicalWidth.toInt(),
      'physical_height': physicalHeight.toInt(),
      'device_pixel_ratio': _devicePixelRatio,
      'current_offset_x': currentOffsetX,
      'current_offset_y': currentOffsetY,
    });

    debugPrint('═══════════════════════════════════════');
    debugPrint('📱 DEVICE RESOLUTION INFO');
    debugPrint(
      'Logical Size: ${_deviceWidth.toStringAsFixed(0)}x${_deviceHeight.toStringAsFixed(0)}',
    );
    debugPrint(
      'Physical Size: ${physicalWidth.toStringAsFixed(0)}x${physicalHeight.toStringAsFixed(0)}',
    );
    debugPrint('Device Pixel Ratio: $_devicePixelRatio');
    debugPrint('Device Profile: $_deviceProfile');
    debugPrint('═══════════════════════════════════════');
  }

  /// Get offset corrections for current device
  /// Returns: {offsetX, offsetY}
  Map<String, double> getOffsetCorrections() {
    // Try exact match first
    if (_resolutionOffsets.containsKey(_deviceProfile)) {
      final offsets = _resolutionOffsets[_deviceProfile]!;
      LogService.send({
        'Timestamp': DateTime.now().toUtc().toIso8601String(),
        'action': 'resolution_profile_matched',
        'device_profile': _deviceProfile,
        'offset_x': offsets['offsetX'],
        'offset_y': offsets['offsetY'],
      });
      return offsets;
    }

    // Fallback to defaults if no exact match
    const defaultProfile = "1080x1920";
    final defaultOffsets = _resolutionOffsets[defaultProfile]!;

    LogService.send({
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
      'action': 'resolution_profile_default_fallback',
      'current_profile': _deviceProfile,
      'default_profile': defaultProfile,
      'offset_x': defaultOffsets['offsetX'],
      'offset_y': defaultOffsets['offsetY'],
    });

    return defaultOffsets;
  }

  /// Register/add a new resolution profile (useful for testing)
  void registerResolutionProfile(
    String profile,
    double offsetX,
    double offsetY,
  ) {
    _resolutionOffsets[profile] = {"offsetX": offsetX, "offsetY": offsetY};

    LogService.send({
      'Timestamp': DateTime.now().toUtc().toIso8601String(),
      'action': 'resolution_profile_registered',
      'profile': profile,
      'offset_x': offsetX,
      'offset_y': offsetY,
    });

    debugPrint(
      '✅ Registered resolution profile: $profile (X:$offsetX, Y:$offsetY)',
    );
  }

  /// Get device profile string
  String getDeviceProfile() => _deviceProfile;

  /// Get all registered profiles (for debugging)
  Map<String, Map<String, double>> getAllProfiles() => _resolutionOffsets;

  /// Get current device dimensions
  Map<String, double> getDeviceDimensions() => {
    'logicalWidth': _deviceWidth,
    'logicalHeight': _deviceHeight,
    'devicePixelRatio': _devicePixelRatio,
    'physicalWidth': _deviceWidth * _devicePixelRatio,
    'physicalHeight': _deviceHeight * _devicePixelRatio,
  };
}
