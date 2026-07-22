import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Monotonic build number, injected by CI (`--dart-define=APP_BUILD=<run>`).
/// 0 in local dev builds (we never prompt to "update" a dev build).
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
///  • Android → downloads APK, launches system installer.
///  • Windows → downloads zip, extracts, replaces files, relaunches silently.
///  • Other → opens release page.
class Updater {
  Updater._();
  static final Updater instance = Updater._();

  static const _releaseApi = 'https://api.github.com/repos/Sidimad-tv/Ultimate-v1/releases/latest';

  String get currentLabel => kBuildNumber == 0 ? 'dev build' : 'Build $kBuildNumber';

  bool get canSelfInstall => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  /// Returns update info if a newer build is published, else null.
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

  /// Android: download APK with progress (0..1) then open installer.
  Future<void> downloadAndInstallApk(UpdateInfo info, {void Function(double)? onProgress}) async {
    if (info.apkUrl == null) throw Exception('No Android build available.');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/sidimad-update-${info.build}.apk');
    await _downloadFile(info.apkUrl!, file, onProgress);
    final r = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (r.type != ResultType.done) throw Exception(r.message);
  }

  /// Windows: download zip with progress, extract, replace files, relaunch.
  Future<void> downloadAndInstallWindows(UpdateInfo info, {void Function(double)? onProgress}) async {
    if (info.windowsZipUrl == null) throw Exception('No Windows build available.');
    final dir = await getTemporaryDirectory();
    final zipFile = File('${dir.path}/sidimad-update-${info.build}.zip');
    final extractDir = Directory('${dir.path}/sidimad-extract-${info.build}');

    // 1. Download zip with progress
    await _downloadFile(info.windowsZipUrl!, zipFile, onProgress);

    // 2. Extract zip using PowerShell
    if (extractDir.existsSync()) extractDir.deleteSync(recursive: true);
    extractDir.createSync();
    final psExtract = await Process.run('powershell', [
      '-NoProfile', '-Command',
      'Expand-Archive -Path "${zipFile.path}" -DestinationPath "${extractDir.path}" -Force',
    ]);
    if (psExtract.exitCode != 0) throw Exception('Failed to extract update: ${psExtract.stderr}');

    // 3. Find the exe directory (where the running app lives)
    final exePath = Platform.resolvedExecutable;
    final appDir = Directory(p.dirname(exePath));

    // 4. Copy all extracted files over the current installation
    await _copyDirectory(extractDir, appDir);

    // 5. Launch new exe
    await Process.start(exePath, [], mode: ProcessStartMode.detached);

    // 6. Kill this process
    exit(0);
  }

  /// Recursively copy [src] into [dst], overwriting existing files.
  Future<void> _copyDirectory(Directory src, Directory dst) async {
    dst.createSync(recursive: true);
    await for (final entity in src.list(recursive: true)) {
      final rel = p.relative(entity.path, from: src.path);
      final target = File('${dst.path}/$rel');
      if (entity is File) {
        target.createSync(recursive: true);
        await entity.copy(target.path);
      } else if (entity is Directory) {
        target.createSync(recursive: true);
      }
    }
  }

  /// Download [url] to [file] with progress callback (0..1).
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
