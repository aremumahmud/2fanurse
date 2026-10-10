import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the paired device's TOTP secret in the platform Keychain
/// (iOS) / Keystore (Android) — never in plain files or SharedPreferences.
class DeviceStore {
  DeviceStore._();
  static final instance = DeviceStore._();

  final _storage = const FlutterSecureStorage();

  static const _secretKey = 'totp_secret';
  static const _labelKey = 'device_label';

  Future<PairedDevice?> read() async {
    final secret = await _storage.read(key: _secretKey);
    final label = await _storage.read(key: _labelKey);
    if (secret == null || label == null) return null;
    return PairedDevice(secret: secret, label: label);
  }

  Future<void> save(PairedDevice device) async {
    await _storage.write(key: _secretKey, value: device.secret);
    await _storage.write(key: _labelKey, value: device.label);
  }

  Future<void> clear() async {
    await _storage.delete(key: _secretKey);
    await _storage.delete(key: _labelKey);
  }
}

class PairedDevice {
  final String secret;
  final String label;

  const PairedDevice({required this.secret, required this.label});
}
