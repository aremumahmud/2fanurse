import 'package:flutter/material.dart';

import 'screens/code_screen.dart';
import 'screens/pairing_screen.dart';
import 'services/device_store.dart';

void main() {
  runApp(const NurseDeviceAuthApp());
}

class NurseDeviceAuthApp extends StatelessWidget {
  const NurseDeviceAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care RAG Authenticator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const _RootScreen(),
    );
  }
}

class _RootScreen extends StatefulWidget {
  const _RootScreen();

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  PairedDevice? _device;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final device = await DeviceStore.instance.read();
    setState(() {
      _device = device;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_device == null) {
      return PairingScreen(onPaired: (device) => setState(() => _device = device));
    }

    return CodeScreen(
      device: _device!,
      onUnpaired: () => setState(() => _device = null),
    );
  }
}
