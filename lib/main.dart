import 'package:aera_flutter/aera_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import 'aera/runtime.dart';
import 'src/rust/api/aera.dart';

Future<void> main() async {
  await initAera();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AERA App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      // Routes AERA's back gesture to this app's navigator.
      builder: (context, child) => AeraScope(child: child!),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = '';

  Future<void> _beep() async {
    try {
      await playTone(frequencyHz: 880, milliseconds: 200, volume: 0.3);
      setState(() => _status = 'Played a tone');
    } catch (error) {
      setState(() => _status = 'No speaker here: ${error is AnyhowException ? error.message : error}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final where = inRecovery() ? 'AERA Recovery' : 'a PC';
    return Scaffold(
      appBar: AppBar(title: const Text('AERA App')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Running on $where',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Language: ${recoveryLocale()}'),
            Text('Your files: ${storageDirs().appData}'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _beep,
              icon: const Icon(Icons.volume_up),
              label: const Text('Beep from Rust'),
            ),
            const SizedBox(height: 8),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
