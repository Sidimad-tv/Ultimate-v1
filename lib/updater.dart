import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Monotonic build number, injected by CI (`--dart-define=APP_BUILD=<run>`).
const int kBuildNumber = int.fromEnvironment('APP_BUILD', defaultValue: 0);

class UpdateInfo {
  final int build;
  final String name;
  final String notes;
  final String? apkUrl;
  final String? windowsZipUrl;
  final String releaseUrl;
  UpdateInfo({required this.build, required this.name, required this.notes, this.apkUrl, this.windowsZipUrl, required this.releaseUrl});
}

/// Self-update against the project's rolling GitHub "latest" release.
class Updater {
  Updater._();
  static final Updater instance = Updater._();

  static const _releaseApi = 'https://api.github.com/repos/Sidimad-tv/Ultimate-v1/releases/latest';

  String get currentLabel => kBuildNumber == 0 ? 'dev build' : 'Build $kBuildNumber';

  bool get canSelfInstall => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  // ── Check for update ──────────────────────────────────────────────────────

  Future<UpdateInfo?> check() async {
    try {
      final res = await http
          .get(Uri.parse(_releaseApi), headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'Sidimad-XtreamProv1'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final name = (j['name'] ?? '').toString();
      final body = (j['body'] ?? '').toString();
      final latest = _parseBuild(body) ?? _parseBuild(name);
      if (latest == null || latest <= kBuildNumber) return null;

      String? apk;
      String? winZip;
      for (final a in (j['assets'] as List? ?? const [])) {
        final n = (a['name'] ?? '').toString();
        if (n == 'Sidimad-XtreamProv1-Android.apk') apk = a['browser_download_url'];
        if (n == 'Sidimad-XtreamProv1-Windows.zip') winZip = a['browser_download_url'];
      }
      return UpdateInfo(
        build: latest,
        name: name.isEmpty ? 'Build $latest' : name,
        notes: body.replaceFirst(RegExp(r'build:\s*\d+\s*'), '').trim(),
        apkUrl: apk,
        windowsZipUrl: winZip,
        releaseUrl: (j['html_url'] ?? 'https://github.com/Sidimad-tv/Ultimate-v1/releases/latest').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  int? _parseBuild(String s) {
    final m = RegExp(r'build:\s*(\d+)', caseSensitive: false).firstMatch(s) ?? RegExp(r'Build\s+(\d+)').firstMatch(s);
    return m == null ? null : int.tryParse(m.group(1)!);
  }

  // ── Android ───────────────────────────────────────────────────────────────

  Future<void> downloadAndInstallApk(UpdateInfo info, {void Function(double)? onProgress}) async {
    if (info.apkUrl == null) throw Exception('No Android build available.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sidimad-update-${info.build}.apk');
    await _downloadFile(info.apkUrl!, file, onProgress);
    final r = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (r.type != ResultType.done) throw Exception(r.message);
  }

  // ── Windows: download + extract ───────────────────────────────────────────
  // Returns the extract directory path. Call [applyWindowsUpdate] to relaunch.

  Future<String> prepareWindowsUpdate(UpdateInfo info, {void Function(double)? onProgress}) async {
    if (info.windowsZipUrl == null) throw Exception('No Windows build available.');
    final dir = await getTemporaryDirectory();
    final zipFile = File('${dir.path}/sidimad-update-${info.build}.zip');
    final extractDir = Directory('${dir.path}/sidimad-extract-${info.build}');

    // Download zip with progress
    await _downloadFile(info.windowsZipUrl!, zipFile, onProgress);

    // Extract
    if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
    extractDir.createSync(recursive: true);
    final ps = await Process.run('powershell', [
      '-NoProfile', '-Command',
      'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${extractDir.path}" -Force',
    ]);
    if (ps.exitCode != 0) throw Exception('Extract failed: ${ps.stderr}');

    return extractDir.path;
  }

  // ── Windows: apply update (restart now) ───────────────────────────────────
  // Writes a helper bat, launches it, exits the current process.

  Future<void> applyWindowsUpdate(String extractDirPath) async {
    final exePath = Platform.resolvedExecutable;
    final appDir = p.dirname(exePath);
    final exeName = p.basename(exePath);

    final dir = await getTemporaryDirectory();
    final batFile = File('${dir.path}/sidimad-restart.bat');

    // The bat: waits for process exit, copies files, relaunches exe, deletes itself
    final batContent = '''@echo off
timeout /t 3 /nobreak >nul
xcopy /Y /E /I /Q "${extractDirPath}\\*" "${appDir}\\"
start "" "${appDir}\\${exeName}"
del "%~f0"
''';
    await batFile.writeAsString(batContent);
    await Process.start('cmd', ['/c', batFile.path], mode: ProcessStartMode.detached);
    exit(0);
  }

  // ── Windows: apply on next launch ─────────────────────────────────────────
  // Checks for a pending-update marker file and applies it.

  Future<void> applyPendingWindowsUpdate() async {
    try {
      final dir = await getTemporaryDirectory();
      final marker = File('${dir.path}/sidimad-pending-update.txt');
      if (!marker.existsSync()) return;
      final extractDirPath = marker.readAsStringSync().trim();
      marker.deleteSync();
      final extractDir = Directory(extractDirPath);
      if (!extractDir.existsSync()) return;

      final exePath = Platform.resolvedExecutable;
      final appDir = p.dirname(exePath);
      final exeName = p.basename(exePath);

      final batFile = File('${dir.path}/sidimad-restart.bat');
      final batContent = '''@echo off
timeout /t 2 /nobreak >nul
xcopy /Y /E /I /Q "${extractDirPath}\\*" "${appDir}\\"
start "" "${appDir}\\${exeName}"
del "%~f0"
''';
      await batFile.writeAsString(batContent);
      await Process.start('cmd', ['/c', batFile.path], mode: ProcessStartMode.detached);
      exit(0);
    } catch (_) {}
  }

  // ── Windows: save for later ───────────────────────────────────────────────

  Future<void> savePendingWindowsUpdate(String extractDirPath) async {
    final dir = await getTemporaryDirectory();
    final marker = File('${dir.path}/sidimad-pending-update.txt');
    await marker.writeAsString(extractDirPath);
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  Future<void> _downloadFile(String url, File file, void Function(double)? onProgress) async {
    final client = http.Client();
    try {
      final resp = await client.send(http.Request('GET', Uri.parse(url)));
      if (resp.statusCode >= 400) throw Exception('HTTP ${resp.statusCode}');
      final total = resp.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      await for (final chunk in resp.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }
}
