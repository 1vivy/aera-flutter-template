import 'package:flutter/material.dart';
import 'package:surfaces/surfaces.dart';
import 'package:surfaces_aera/surfaces_aera.dart';
import 'package:surfaces_ui/surfaces_ui.dart';
import 'package:surfaces_webui/surfaces_webui.dart';

import 'native/native.dart';

Future<void> main() async {
  // The id is the KernelSU module id; keep it equal to surfaces.yaml's.
  await Surface.init(
    await withNative(const SurfaceConfig(appId: 'surfaces_app', appName: 'Surfaces App')),
    // The platforms this app targets. The first that recognises the host
    // wins; desktop and tests fall back to plain dart:io.
    backends: const [WebUiBackend(), AeraBackend()],
  );
  runApp(const SurfacesApp(title: 'Surfaces App', home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _surface = Surface.instance;
  String _greeting = '';
  JobStatus? _job;
  Job? _running;

  @override
  void initState() {
    super.initState();
    try {
      _greeting = _surface.core.call('greet', {'name': _surface.info.name}) as String;
    } on OpsException catch (error) {
      _greeting = 'No Rust core here (${error.message})';
    }
  }

  Future<void> _count() async {
    try {
      final job = await _surface.ops.start('app.count', {'to': 6});
      setState(() => _running = job);
      await for (final status in job.updates) {
        setState(() => _job = status);
      }
    } on OpsException catch (error) {
      await _surface.feedback.toast(error.message);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      appBar: AppBar(title: const Text('Surfaces App')),
      body: PageBody(
        children: [
          const HostBanner(),
          SectionCard(title: 'Rust core', child: Text(_greeting)),
          SectionCard(
            title: 'Ops job',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_surface.ops.available
                    ? 'Runs through ${_surface.ops.transportName}'
                    : 'Not on this host: ${_surface.ops.why}'),
                const SizedBox(height: Gap.s),
                if (job != null) ...[
                  LinearProgressIndicator(value: job.progress),
                  const SizedBox(height: Gap.xs),
                  Text(job.finished ? '${job.state.name}: ${job.result ?? job.error?.message}' : job.message ?? ''),
                  const SizedBox(height: Gap.s),
                ],
                Row(
                  children: [
                    FilledButton(
                      onPressed: _running == null && _surface.ops.available ? _count : null,
                      child: const Text('Count to 6'),
                    ),
                    const SizedBox(width: Gap.s),
                    if (_running != null)
                      OutlinedButton(onPressed: _running!.cancel, child: const Text('Cancel')),
                  ],
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => _surface.feedback.toast('Hello from ${_surface.info.name}'),
            child: const Text('Show a toast'),
          ),
        ],
      ),
    );
  }
}
