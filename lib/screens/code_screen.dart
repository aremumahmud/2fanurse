import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/device_store.dart';
import '../services/totp.dart';

class CodeScreen extends StatefulWidget {
  final PairedDevice device;
  final VoidCallback onUnpaired;

  const CodeScreen({super.key, required this.device, required this.onUnpaired});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  late String _code;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _code = Totp.generate(widget.device.secret);
    _secondsLeft = Totp.secondsRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    setState(() {
      _code = Totp.generate(widget.device.secret);
      _secondsLeft = Totp.secondsRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _confirmUnpair() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair this device?'),
        content: const Text(
          "This phone will stop working for nurse sign-in until an admin generates a new pairing code.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DeviceStore.instance.clear();
      widget.onUnpaired();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedCode = '${_code.substring(0, 3)} ${_code.substring(3)}';
    final progress = _secondsLeft / Totp.periodSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Care RAG Authenticator')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.device.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                      ),
                    ),
                    Text('$_secondsLeft', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  formattedCode,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter this code with your password to sign in',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _confirmUnpair,
                  child: const Text('Unpair this device'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
