import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models.dart';
import '../store.dart';
import '../widgets.dart';
import '../theme.dart';
import '../xtream.dart';

class LoginScreen extends StatefulWidget {
  final void Function(XtreamCredentials) onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;
  List<XtreamCredentials> _profiles = [];
  XtreamCredentials? _selectedProfile;

  @override
  void initState() {
    super.initState();
    Store.savedProfiles().then((p) => setState(() => _profiles = p));
  }

  Future<void> _connect(XtreamCredentials c) async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await XtreamClient(c).authenticate();
      if (!mounted) return;
      await Store.setActive(c);
      if (mounted) widget.onLogin(c);
    } catch (e) {
      if (!c.isM3u && c.username.isNotEmpty) {
        final m3uUrl =
            '${c.baseUrl}/get.php?username=${Uri.encodeComponent(c.username)}&password=${Uri.encodeComponent(c.password)}&type=m3u_plus';
        final m3uCreds = XtreamCredentials(
          baseUrl: c.baseUrl,
          username: c.username,
          password: c.password,
          m3uUrl: m3uUrl,
        );
        try {
          await XtreamClient(m3uCreds).authenticate();
          if (!mounted) return;
          await Store.setActive(m3uCreds);
          if (mounted) widget.onLogin(m3uCreds);
          return;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  void _fillTest(String server, String user, String pass) {
    setState(() {
      _url.text = server;
      _user.text = user;
      _pass.text = pass;
      _error = null;
    });
  }

  Future<void> _loadLocalM3u() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        setState(() => _error = 'File is empty.');
        return;
      }
      final name = result.files.single.name;
      final creds = XtreamCredentials(
        baseUrl: 'local',
        username: name,
        password: '',
        m3uUrl: Uri.file(file.path).toString(),
      );
      _connect(creds);
    } catch (e) {
      setState(() => _error = 'Failed to load file: $e');
    }
  }

  Future<void> _pasteUrl() async {
    final urlCtrl = TextEditingController();
    final epgCtrl = TextEditingController();
    String? err;
    final creds = await showDialog<XtreamCredentials>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: surface,
          title: const Text('Add M3U / playlist'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: urlCtrl,
                autocorrect: false,
                enableSuggestions: false,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Playlist URL', hintText: 'https://…/playlist.m3u  or  get.php?username=…'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: epgCtrl,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(labelText: 'XMLTV EPG URL (optional)', hintText: 'https://…/epg.xml'),
              ),
              const SizedBox(height: 6),
              Text('Tip: Xtream links bring the full catalog. Plain .m3u links load live channels.',
                  style: TextStyle(color: subtle, fontSize: 11.5)),
              if (err != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(err!, style: const TextStyle(color: Color(0xFFFFB4B4), fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: muted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: bg),
              onPressed: () {
                final raw = urlCtrl.text.trim();
                if (raw.isEmpty) {
                  setLocal(() => err = 'Enter a playlist URL.');
                  return;
                }
                final x = credentialsFromUrl(raw);
                if (x != null) {
                  Navigator.pop(ctx, x);
                  return;
                }
                if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(raw)) {
                  setLocal(() => err = 'Enter a valid http(s) URL.');
                  return;
                }
                final epg = epgCtrl.text.trim();
                Navigator.pop(
                  ctx,
                  XtreamCredentials(
                    baseUrl: raw,
                    username: Uri.tryParse(raw)?.host ?? 'playlist',
                    password: '',
                    m3uUrl: raw,
                    epgUrl: epg.isEmpty ? null : epg,
                  ),
                );
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
    if (creds != null) _connect(creds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _blob(accent.withValues(alpha: 0.18), 320),
          ),
          Positioned(bottom: -100, right: -60, child: _blob(accent2.withValues(alpha: 0.12), 280)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wordmark(size: 42),
                    const SizedBox(height: 14),
                    Text('Sign in with your Xtream / X3U codes — or paste an M3U URL.',
                        textAlign: TextAlign.center, style: TextStyle(color: muted)),
                    const SizedBox(height: 24),
                    if (_profiles.isNotEmpty) ...[
                      GestureDetector(
                        onTap: _busy ? null : () => _showPlaylistPicker(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: line),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.playlist_play_rounded, color: accent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedProfile != null
                                      ? _profileLabel(_selectedProfile!)
                                      : 'Saved Playlists (${_profiles.length})',
                                  style: TextStyle(
                                    color: _selectedProfile != null ? textHi : muted,
                                    fontSize: 14,
                                    fontWeight: _selectedProfile != null ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down_rounded, color: muted, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Divider(color: line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or add new', style: TextStyle(color: subtle, fontSize: 11)),
                          ),
                          Expanded(child: Divider(color: line)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    _field(_url, 'Server URL', hint: 'http://host:3550'),
                    const SizedBox(height: 12),
                    _field(_user, 'Username'),
                    const SizedBox(height: 12),
                    _field(_pass, 'Password', obscure: true),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFFFB4B4))),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: bg,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _busy
                            ? null
                            : () => _connect(XtreamCredentials(
                                  baseUrl: normalizeBaseUrl(_url.text),
                                  username: _user.text.trim(),
                                  password: _pass.text.trim(),
                                )),
                        child: _busy
                            ? SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: bg))
                            : const Text('Connect', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: _busy ? null : _pasteUrl,
                      icon: Icon(Icons.link_rounded, size: 18, color: accent),
                      label: Text('Have an M3U / playlist URL?',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : _loadLocalM3u,
                      icon: Icon(Icons.folder_open_rounded, size: 18, color: accent),
                      label: Text('Load local M3U file',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),
                    Text('Test Servers', style: TextStyle(color: subtle, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _testBtn('mysql360', 'http://mysql360.life:2095', 'w1853', '586881003'),
                        _testBtn('websafety', 'http://websafety101.net:5050', 'greerlint@gmail.com', 'STYDDhHcwZ'),
                        _testBtn('lucastv', 'http://10k.lucastv.pro', 'bMzUj4zG', 'eR7gYGT'),
                        _testBtn('lefanten', 'http://lefanten.com:8080', 'OezkaraTV', 'bUt6zbg'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Credentials are stored only on this device.',
                        style: TextStyle(color: subtle, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testBtn(String label, String server, String user, String pass) {
    return ActionChip(
      avatar: Icon(Icons.bolt_rounded, size: 14, color: accent),
      label: Text(label, style: TextStyle(color: textHi, fontSize: 11)),
      backgroundColor: surface,
      side: BorderSide(color: line),
      onPressed: _busy ? null : () => _fillTest(server, user, pass),
    );
  }

  Widget _field(TextEditingController c, String label, {String? hint, bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  String _profileLabel(XtreamCredentials p) {
    final host = p.baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    final type = p.isM3u ? 'M3U' : 'Xtream';
    return '${p.username}  ($host)  [$type]';
  }

  void _showPlaylistPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Saved Playlists', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textHi)),
            const SizedBox(height: 12),
            for (final p in _profiles) ...[
              ListTile(
                leading: Icon(
                  _selectedProfile == p ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _selectedProfile == p ? accent : muted,
                  size: 22,
                ),
                title: Text(p.username, style: TextStyle(color: textHi, fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(
                  '${p.baseUrl.replaceFirst(RegExp(r'^https?://'), '')}  [${p.isM3u ? 'M3U' : 'Xtream'}]',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedProfile = p);
                  _connect(p);
                },
              ),
              if (p != _profiles.last) Divider(height: 1, color: line),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}
