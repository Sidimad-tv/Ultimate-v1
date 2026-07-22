import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../updater.dart';

/// Shows the "Update available" dialog and runs the right install path per
/// platform (Android = APK install, Windows = silent zip replace, others = link).
Future<void> showUpdateFlow(BuildContext context, UpdateInfo info) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _busy = false;
  double _progress = 0;
  String? _error;
  String _statusText = '';

  Future<void> _run() async {
    final info = widget.info;
    setState(() {
      _busy = true;
      _error = null;
      _statusText = 'Preparing…';
    });
    try {
      if (Platform.isAndroid && info.apkUrl != null) {
        setState(() => _statusText = 'Downloading APK…');
        await Updater.instance.downloadAndInstallApk(info, onProgress: (p) {
          if (mounted) setState(() {
            _progress = p;
            _statusText = 'Downloading APK… ${(p * 100).round()}%';
          });
        });
        if (mounted) Navigator.of(context).pop();
      } else if (Platform.isWindows && info.windowsZipUrl != null) {
        setState(() => _statusText = 'Downloading update…');
        await Updater.instance.downloadAndInstallWindows(info, onProgress: (p) {
          if (mounted) setState(() {
            _progress = p;
            _statusText = 'Downloading update… ${(p * 100).round()}%';
          });
        });
        if (mounted) Navigator.of(context).pop();
      } else {
        // Fallback: open release page
        setState(() => _statusText = 'Opening download page…');
        await launchUrl(Uri.parse(info.releaseUrl), mode: LaunchMode.externalApplication);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() {
        _busy = false;
        _error = 'Update failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final canInstall = Updater.instance.canSelfInstall &&
        ((Platform.isAndroid && info.apkUrl != null) || (Platform.isWindows && info.windowsZipUrl != null));
    return AlertDialog(
      backgroundColor: surface,
      title: Row(children: [
        Icon(Icons.system_update_rounded, color: accent),
        const SizedBox(width: 10),
        const Expanded(child: Text('Update available')),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (info.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(child: Text(info.notes, style: TextStyle(color: muted, fontSize: 13, height: 1.4))),
            ),
          ],
          if (!canInstall) ...[
            const SizedBox(height: 10),
            Text('This opens the release page to download the new build.', style: TextStyle(color: subtle, fontSize: 12)),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 6,
                backgroundColor: surfaceHi,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(_statusText, style: TextStyle(color: subtle, fontSize: 12)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text('Later', style: TextStyle(color: muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
          onPressed: _busy ? null : _run,
          child: Text(canInstall ? 'Update now' : 'Get update'),
        ),
      ],
    );
  }
}
