import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// RFC 6238 TOTP, matching the server's `otpauth` defaults:
/// HMAC-SHA1, 6 digits, 30-second period.
class Totp {
  static const int digits = 6;
  static const int periodSeconds = 30;

  /// Generates the current 6-digit code for a base32-encoded secret.
  static String generate(String base32Secret, {DateTime? at}) {
    final time = at ?? DateTime.now().toUtc();
    final counter = time.millisecondsSinceEpoch ~/ 1000 ~/ periodSeconds;
    return _generateForCounter(base32Secret, counter);
  }

  /// Seconds remaining until the current code rotates.
  static int secondsRemaining({DateTime? at}) {
    final time = at ?? DateTime.now().toUtc();
    final elapsed = (time.millisecondsSinceEpoch ~/ 1000) % periodSeconds;
    return periodSeconds - elapsed;
  }

  static String _generateForCounter(String base32Secret, int counter) {
    final keyBytes = _base32Decode(base32Secret);
    final counterBytes = ByteData(8)..setInt64(0, counter, Endian.big);
    final digest = Hmac(sha1, keyBytes).convert(counterBytes.buffer.asUint8List());
    final bytes = digest.bytes;

    final offset = bytes[bytes.length - 1] & 0xf;
    final binary = ((bytes[offset] & 0x7f) << 24) |
        ((bytes[offset + 1] & 0xff) << 16) |
        ((bytes[offset + 2] & 0xff) << 8) |
        (bytes[offset + 3] & 0xff);

    final code = binary % _pow10(digits);
    return code.toString().padLeft(digits, '0');
  }

  static int _pow10(int n) {
    var result = 1;
    for (var i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }

  static const _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static Uint8List _base32Decode(String input) {
    final cleaned = input.toUpperCase().replaceAll('=', '').replaceAll(RegExp(r'\s'), '');
    final output = <int>[];
    var buffer = 0;
    var bitsLeft = 0;

    for (final char in cleaned.split('')) {
      final value = _base32Alphabet.indexOf(char);
      if (value < 0) continue; // skip invalid characters defensively
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        output.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }
    return Uint8List.fromList(output);
  }
}
