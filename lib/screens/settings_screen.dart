import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _bgmVolume = 0.5;
  double _sfxVolume = 0.5;
  double _textSpeed = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Volume BGM'),
            Slider(
              value: _bgmVolume,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _bgmVolume = v),
            ),
            const SizedBox(height: 16),
            const Text('Volume SFX'),
            Slider(
              value: _sfxVolume,
              min: 0,
              max: 1,
              onChanged: (v) => setState(() => _sfxVolume = v),
            ),
            const SizedBox(height: 16),
            const Text('Velocidade do texto (ms por letra)'),
            Slider(
              value: _textSpeed,
              min: 10,
              max: 100,
              divisions: 18,
              label: _textSpeed.round().toString(),
              onChanged: (v) => setState(() => _textSpeed = v),
            ),
          ],
        ),
      ),
    );
  }
}
