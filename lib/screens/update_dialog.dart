import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../updater.dart';

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
  String _statusText = '';
  String? _error;
  // After Windows download+extract, store the path and show restart prompt
  String? _pendingExtractPath;

  Future<void> _download() async {
    final info = widget.info;
    setState(() {
      _busy = true;
      _error = null;
      _statusText = 'Downloading…';
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
        final extractPath = await Updater.instance.prepareWindowsUpdate(info, onProgress: (p) {
          if (mounted) setState(() {
            _progress = p;
            _statusText = 'Downloading… ${(p * 100).round()}%';
          });
        });
        // Download done — show restart confirmation
        if (mounted) setState(() {
          _busy = false;
          _pendingExtractPath = extractPath;
          _statusText = 'Update ready!';
        });

      } else {
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

  void _restartNow() {
    if (_pendingExtractPath == null) return;
    Updater.instance.applyWindowsUpdate(_pendingExtractPath!);
  }

  void _restartLater() {
    if (_pendingExtractPath == null) return;
    Updater.instance.savePendingWindowsUpdate(_pendingExtractPath!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final canInstall = Updater.instance.canSelfInstall &&
        ((Platform.isAndroid && info.apkUrl != null) || (Platform.isWindows && info.windowsZipUrl != null));
    final showRestartPrompt = _pendingExtractPath != null;

    return AlertDialog(
      backgroundColor: surface,
      title: Row(children: [
        Icon(
          showRestartPrompt ? Icons.check_circle_rounded : Icons.system_update_rounded,
          color: showRestartPrompt ? const Color(0xFF66FFAA) : accent,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(showRestartPrompt ? 'Update ready' : 'Update available')),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (info.notes.isNotEmpty && !showRestartPrompt) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(child: Text(info.notes, style: TextStyle(color: muted, fontSize: 13, height: 1.4))),
            ),
          ],
          if (!canInstall && !showRestartPrompt) ...[
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
          if (showRestartPrompt) ...[
            const SizedBox(height: 12),
            Text(
              'The update has been downloaded and extracted. Restart now to apply it, or apply it the next time you open the app.',
              style: TextStyle(color: muted, fontSize: 13, height: 1.4),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
          ],
        ],
      ),
      actions: [
        if (showRestartPrompt) ...[
          TextButton(
            onPressed: _restartLater,
            child: Text('Later', style: TextStyle(color: muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
            onPressed: _restartNow,
            child: const Text('Restart now'),
          ),
        ] else ...[
          TextButton(
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
            child: Text('Later', style: TextStyle(color: muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
            onPressed: _busy ? null : _download,
            child: Text(canInstall ? 'Update now' : 'Get update'),
          ),
        ],
      ],
    );
  }
}
