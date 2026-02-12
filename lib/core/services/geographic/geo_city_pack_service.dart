import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:avrai/core/services/infrastructure/supabase_service.dart';

/// Downloads + caches geo city packs (v1).
///
/// Pack layout (unzipped folder):
/// - metadata.json
/// - localities.geojson
/// - index.json
/// - vibes.json
/// - knots.json
/// - summaries.json
class GeoCityPackService {
  static const String _logName = 'GeoCityPackService';

  final SupabaseService _supabase;
  final Directory? _rootDirOverride;

  GeoCityPackService({
    SupabaseService? supabase,
    Directory? rootDir,
  })  : _supabase = supabase ?? SupabaseService(),
        _rootDirOverride = rootDir;

  bool _isRunningInFlutterTest() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<Directory> _packsRoot() async {
    if (kIsWeb) {
      throw UnsupportedError('Geo city packs are not supported on web.');
    }

    if (_rootDirOverride != null) return _rootDirOverride;

    // In widget tests, path_provider may not be available; fall back to systemTemp.
    Directory baseDir;
    if (_isRunningInFlutterTest()) {
      baseDir = Directory.systemTemp;
    } else {
      try {
        baseDir = await getApplicationSupportDirectory();
      } catch (_) {
        // Some test/CI environments don't have path_provider channels initialized.
        baseDir = Directory.systemTemp;
      }
    }

    final root = Directory(p.join(baseDir.path, 'geo_packs_v1'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<Directory> packDirForCity(String cityCode) async {
    final root = await _packsRoot();
    final dir = Directory(p.join(root.path, cityCode));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// List city_codes that have an installed (current) pack on disk.
  ///
  /// Best-effort: returns empty list if filesystem access is unavailable.
  Future<List<String>> listInstalledCityCodes() async {
    try {
      final root = await _packsRoot();
      if (!await root.exists()) return const [];
      final out = <String>[];
      await for (final e in root.list(followLinks: false)) {
        if (e is! Directory) continue;
        final cityCode = p.basename(e.path);
        if (cityCode.isEmpty) continue;
        final currentFile = File(p.join(e.path, 'current.txt'));
        if (await currentFile.exists()) {
          out.add(cityCode);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, dynamic>?> getManifest(String cityCode) async {
    try {
      final c = _supabase.tryGetClient();
      if (c == null) return null;
      final res = await c.rpc('geo_get_city_pack_manifest_v1', params: {
        'p_city_code': cityCode,
      });
      if (res is! List || res.isEmpty) return null;
      return Map<String, dynamic>.from(res.first as Map);
    } catch (e, st) {
      developer.log(
        'Failed to fetch pack manifest',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readInstalledManifest(String cityCode) async {
    try {
      final dir = await packDirForCity(cityCode);
      final f = File(p.join(dir.path, 'installed_manifest.json'));
      if (!await f.exists()) return null;
      final decoded = jsonDecode(await f.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeInstalledManifest({
    required String cityCode,
    required Map<String, dynamic> manifest,
  }) async {
    final dir = await packDirForCity(cityCode);
    final f = File(p.join(dir.path, 'installed_manifest.json'));
    await f.writeAsString(jsonEncode(manifest), flush: true);
  }

  Future<bool> _verifySha256({
    required List<int> bytes,
    required String expectedHex,
  }) async {
    final digest = sha256.convert(bytes).toString();
    return digest.toLowerCase() == expectedHex.toLowerCase();
  }

  Future<void> _extractZipSafely({
    required List<int> zipBytes,
    required Directory destDir,
  }) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final entry in archive) {
      final name = entry.name;
      if (name.isEmpty) continue;

      // Prevent Zip Slip.
      final outPath = p.normalize(p.join(destDir.path, name));
      final destNorm = p.normalize(destDir.path);
      if (!p.isWithin(destNorm, outPath) && outPath != destNorm) {
        throw Exception('Zip entry attempts path traversal: $name');
      }

      if (entry.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        final data = entry.content as List<int>;
        await outFile.writeAsBytes(data, flush: true);
      } else {
        await Directory(outPath).create(recursive: true);
      }
    }
  }

  ({String bucket, String objectPath}) _parseStoragePath(String storagePath) {
    final normalized = storagePath.replaceAll('\\', '/');
    final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (bucket: parts.first, objectPath: parts.skip(1).join('/'));
    }
    // Default bucket.
    return (bucket: 'geo-packs', objectPath: normalized);
  }

  /// Ensure the latest city pack is installed locally (download + unzip), best-effort.
  ///
  /// Returns true if a pack is installed after the call (even if not the latest).
  Future<bool> ensureLatestInstalled(String cityCode) async {
    try {
      final manifest = await getManifest(cityCode);
      if (manifest == null) {
        return (await _readInstalledManifest(cityCode)) != null;
      }

      final latestVersion = (manifest['latest_pack_version'] as num?)?.toInt() ?? 0;
      if (latestVersion <= 0) {
        return (await _readInstalledManifest(cityCode)) != null;
      }

      final installed = await _readInstalledManifest(cityCode);
      final installedVersion = (installed?['latest_pack_version'] as num?)?.toInt() ?? 0;
      if (installedVersion == latestVersion) return true;

      final storagePath = (manifest['storage_path'] ?? '').toString();
      final expectedSha = (manifest['sha256'] ?? '').toString();
      if (storagePath.isEmpty) return installed != null;

      final c = _supabase.tryGetClient();
      if (c == null) return installed != null;

      final parsed = _parseStoragePath(storagePath);
      final bytes = await c.storage.from(parsed.bucket).download(parsed.objectPath);
      if (bytes.isEmpty) return installed != null;

      if (expectedSha.isNotEmpty) {
        final ok = await _verifySha256(bytes: bytes, expectedHex: expectedSha);
        if (!ok) {
          developer.log(
            'Pack sha256 mismatch; refusing install (expected=$expectedSha)',
            name: _logName,
          );
          return installed != null;
        }
      }

      final dir = await packDirForCity(cityCode);
      final vDir = Directory(p.join(dir.path, 'v$latestVersion'));
      if (await vDir.exists()) {
        // Replace directory to avoid stale files.
        await vDir.delete(recursive: true);
      }
      await vDir.create(recursive: true);

      await _extractZipSafely(zipBytes: bytes, destDir: vDir);

      // Atomically switch “current” pointer by writing a marker file.
      final currentFile = File(p.join(dir.path, 'current.txt'));
      await currentFile.writeAsString('v$latestVersion', flush: true);

      await _writeInstalledManifest(cityCode: cityCode, manifest: manifest);
      return true;
    } catch (e, st) {
      developer.log(
        'Failed to ensure pack installed for $cityCode',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return (await _readInstalledManifest(cityCode)) != null;
    }
  }

  Future<Directory?> getCurrentPackDir(String cityCode) async {
    try {
      final dir = await packDirForCity(cityCode);
      final currentFile = File(p.join(dir.path, 'current.txt'));
      if (!await currentFile.exists()) return null;
      final name = (await currentFile.readAsString()).trim();
      if (name.isEmpty) return null;
      final d = Directory(p.join(dir.path, name));
      return await d.exists() ? d : null;
    } catch (_) {
      return null;
    }
  }

  /// Best-effort download of the latest pack zip and store it locally.
  ///
  /// Returns the zip file path if downloaded; does not unzip.
  Future<File?> downloadLatestPackZip(String cityCode) async {
    // Kept for compatibility with early callers; prefer ensureLatestInstalled().
    final manifest = await getManifest(cityCode);
    if (manifest == null) return null;

    final storagePath = (manifest['storage_path'] ?? '').toString();
    final sha = (manifest['sha256'] ?? '').toString();
    if (storagePath.isEmpty) return null;

    final c = _supabase.tryGetClient();
    if (c == null) return null;

    try {
      final dir = await packDirForCity(cityCode);
      final zipFile = File(p.join(dir.path, 'pack.zip'));

      final parsed = _parseStoragePath(storagePath);
      final bytes = await c.storage.from(parsed.bucket).download(parsed.objectPath);
      if (bytes.isEmpty) return null;

      await zipFile.writeAsBytes(bytes, flush: true);

      if (sha.isNotEmpty) {
        final ok = await _verifySha256(bytes: bytes, expectedHex: sha);
        if (!ok) {
          developer.log(
            'Pack sha256 mismatch; refusing download (expected=$sha)',
            name: _logName,
          );
          // Do not keep a bad zip.
          try {
            await zipFile.delete();
          } catch (_) {}
          return null;
        }
      }

      // Store manifest snapshot locally.
      final mFile = File(p.join(dir.path, 'manifest.json'));
      await mFile.writeAsString(jsonEncode(manifest), flush: true);

      return zipFile;
    } catch (e, st) {
      developer.log(
        'Failed to download pack zip',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}
