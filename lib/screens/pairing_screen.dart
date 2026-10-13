import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/device_store.dart';
import '../services/pairing_api.dart';

class PairingScreen extends StatefulWidget {
  final ValueChanged<PairedDevice> onPaired;

  const PairingScreen({super.key, required this.onPaired});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _serverController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _submitting = false;
  bool _scannerConsumed = false;
  String? _error;

  @override
  void dispose() {
    _serverController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _completePairing(PairingPayload payload) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await PairingApi.pair(payload);
      final device = PairedDevice(secret: result.secret, label: result.label);
      try {
        await DeviceStore.instance.save(device);
      } catch (e, st) {
        // Pairing succeeded server-side but saving locally failed — report
        // this distinctly so it isn't mistaken for a pairing/network error.
        debugPrint('DeviceStore.save failed: $e\n$st');
        throw Exception('Paired, but could not save the device locally: $e');
      }
      if (!mounted) return;
      widget.onPaired(device);
    } catch (e, st) {
      debugPrint('Pairing failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _scannerConsumed = false; // allow re-scanning after an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_scannerConsumed || _submitting) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final payload = PairingPayload.tryParse(raw);
    if (payload == null) return;
    _scannerConsumed = true;
    _completePairing(payload);
  }

  void _submitManual() {
    final server = _serverController.text.trim();
    final token = _tokenController.text.trim();
    if (server.isEmpty || token.isEmpty) {
      setState(() => _error = 'Enter both the server address and the pairing code.');
      return;
    }
    _completePairing(PairingPayload(server: server, token: token));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pair this device')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Scan the QR code shown in the admin panel\'s "Add device" dialog.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 320,
                child: Stack(
                  children: [
                    MobileScanner(onDetect: _onQrDetect),
                    if (_submitting)
                      Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or enter manually'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: 'Server address',
                hintText: 'https://your-deployment.example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              enabled: !_submitting,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Pairing code',
                border: OutlineInputBorder(),
              ),
              enabled: !_submitting,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submitManual,
              child: const Text('Pair device'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
