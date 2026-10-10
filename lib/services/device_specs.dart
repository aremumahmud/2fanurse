import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

/// Real device specs, shown to the admin in the Devices page so they can
/// recognize which physical phone a pairing belongs to.
class DeviceSpecs {
  final String platform;
  final String? model;
  final String? osVersion;

  const DeviceSpecs({required this.platform, this.model, this.osVersion});

  static Future<DeviceSpecs> current() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        // `name` is the human-readable name the owner gave the device (e.g.
        // "Jane's iPhone"); `utsname.machine` is a hardware code (e.g.
        // "iPhone15,2") used only if a name isn't available.
        return DeviceSpecs(
          platform: 'iOS',
          model: info.name.isNotEmpty ? info.name : info.utsname.machine,
          osVersion: info.systemVersion,
        );
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return DeviceSpecs(
          platform: 'Android',
          model: '${info.manufacturer} ${info.model}',
          osVersion: 'Android ${info.version.release}',
        );
      }
    } catch (_) {
      // Fall through to the unknown-platform default below.
    }
    return const DeviceSpecs(platform: 'Unknown');
  }
}
