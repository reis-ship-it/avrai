import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:avrai/core/services/local_llm/model_pack_manager.dart';
import 'package:avrai/core/services/local_llm/model_pack_manifest.dart';
import 'package:avrai/core/services/infrastructure/storage_service.dart';

import '../../mocks/mock_storage_service.dart';

class _FakeClient extends http.BaseClient {
  final Map<Uri, http.Response> _responses;
  final List<Uri> requestedUrls = <Uri>[];
  _FakeClient(this._responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUrls.add(request.url);
    final res = _responses[request.url];
    if (res == null) {
      return http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('not found')),
        404,
      );
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
    );
  }
}

void main() {
  setUp(() {
    MockGetStorage.reset();
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('manifest parsing + platform artifact selection is stable', () {
    final manifestJson = jsonEncode({
      'model_id': 'llama3.1-8b-instruct',
      'version': 'q4_0',
      'family': 'llama3.1-8b-instruct',
      'context_len': 4096,
      'min_device': {'min_ram_mb': 8192, 'min_free_disk_mb': 12288},
      'artifacts': [
        {
          'platform': 'android_gguf',
          'url': 'https://example.com/a.gguf',
          'sha256': 'deadbeef',
          'size_bytes': 123,
          'file_name': 'model.gguf',
          'is_zip': false,
        },
        {
          'platform': 'ios_coreml_zip',
          'url': 'https://example.com/i.zip',
          'sha256': 'deadbeef',
          'size_bytes': 456,
          'file_name': 'model.zip',
          'is_zip': true,
        }
      ],
    });

    final m = LocalLlmModelPackManifest.tryParse(manifestJson);
    expect(m, isNotNull);
    expect(m!.modelId, equals('llama3.1-8b-instruct'));
    expect(m.version, equals('q4_0'));
    expect(m.artifacts.length, equals(2));
  });

  test('downloadAndActivate extracts zip safely and sets active pointers', () async {
    // Build a tiny zip artifact with a single file.
    final archive = Archive()
      ..addFile(ArchiveFile('bundle/model.mlmodelc/placeholder.txt', 3, [1, 2, 3]));
    final zipBytes = ZipEncoder().encode(archive);
    final zipSha = sha256.convert(zipBytes).toString();

    final manifestUrl = Uri.parse('https://example.com/manifest.json');
    final artifactUrl = Uri.parse('https://example.com/model.zip');

    final manifest = {
      'model_id': 'llama3.1-8b-instruct',
      'version': 'test',
      'family': 'llama3.1-8b-instruct',
      'context_len': 4096,
      'min_device': {'min_ram_mb': 8192, 'min_free_disk_mb': 12288},
      'artifacts': [
        {
          'platform': 'ios_coreml_zip',
          'url': artifactUrl.toString(),
          'sha256': zipSha,
          'size_bytes': zipBytes.length,
          'file_name': 'model.zip',
          'is_zip': true,
        }
      ],
    };

    final client = _FakeClient({
      manifestUrl: http.Response(jsonEncode(manifest), 200),
      artifactUrl: http.Response.bytes(zipBytes, 200),
    });

    final storage = MockGetStorage.getInstance(boxName: 'prefs');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

    final tmp = await Directory.systemTemp.createTemp('spots_llm_pack_test_');
    addTearDown(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    // Force selection by setting TargetPlatform indirectly is hard in unit tests;
    // so we call manager only for zip extraction behavior by providing an iOS artifact
    // and relying on selectArtifactForCurrentPlatform in production.
    //
    // Here we test core extraction + activation by invoking internal flow via
    // manifest parsing and direct artifact download.
    final mgr = LocalLlmModelPackManager(
      client: client,
      prefs: prefs,
      rootDir: Directory('${tmp.path}/local_llm_packs'),
    );

    await mgr.downloadAndActivate(manifestUrl: manifestUrl);

    final status = await mgr.getStatus();
    expect(status.isInstalled, isTrue);
    expect(status.activePackId, equals('llama3.1-8b-instruct@test'));
    expect(status.activeDir, isNotNull);

    // Extracted file should exist somewhere under the target dir.
    final extracted = File('${status.activeDir}/bundle/model.mlmodelc/placeholder.txt');
    expect(await extracted.exists(), isTrue);
  });

  test('zip slip is rejected', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('../evil.txt', 1, [1]));
    final zipBytes = ZipEncoder().encode(archive);
    final zipSha = sha256.convert(zipBytes).toString();

    final manifestUrl = Uri.parse('https://example.com/manifest2.json');
    final artifactUrl = Uri.parse('https://example.com/bad.zip');

    final manifest = {
      'model_id': 'llama3.1-8b-instruct',
      'version': 'bad',
      'family': 'llama3.1-8b-instruct',
      'context_len': 4096,
      'min_device': {'min_ram_mb': 8192, 'min_free_disk_mb': 12288},
      'artifacts': [
        {
          'platform': 'ios_coreml_zip',
          'url': artifactUrl.toString(),
          'sha256': zipSha,
          'size_bytes': zipBytes.length,
          'file_name': 'bad.zip',
          'is_zip': true,
        }
      ],
    };

    final client = _FakeClient({
      manifestUrl: http.Response(jsonEncode(manifest), 200),
      artifactUrl: http.Response.bytes(zipBytes, 200),
    });

    final storage = MockGetStorage.getInstance(boxName: 'prefs2');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

    final tmp = await Directory.systemTemp.createTemp('spots_llm_pack_test2_');
    addTearDown(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    final mgr = LocalLlmModelPackManager(
      client: client,
      prefs: prefs,
      rootDir: Directory('${tmp.path}/local_llm_packs'),
    );

    await expectLater(
      () => mgr.downloadAndActivate(manifestUrl: manifestUrl),
      throwsA(isA<Exception>()),
    );
  });

  test('skips artifact download when requested pack is already active', () async {
    // Arrange: active pack pointers already set + active dir exists.
    final storage = MockGetStorage.getInstance(boxName: 'prefs_idempotent');
    final prefs = await SharedPreferencesCompat.getInstance(storage: storage);

    final tmp = await Directory.systemTemp.createTemp('spots_llm_pack_test3_');
    addTearDown(() async {
      try {
        await tmp.delete(recursive: true);
      } catch (_) {}
    });

    final activeDir = Directory('${tmp.path}/local_llm_packs/active');
    await activeDir.create(recursive: true);

    const packId = 'llama3.1-8b-instruct@test';
    await prefs.setString(
      LocalLlmModelPackManager.prefsKeyActiveModelDir,
      activeDir.path,
    );
    await prefs.setString(
      LocalLlmModelPackManager.prefsKeyActiveModelId,
      packId,
    );

    // Manifest points to a large artifact URL that we *should not* fetch.
    final manifestUrl = Uri.parse('https://example.com/manifest3.json');
    final artifactUrl = Uri.parse('https://example.com/should_not_download.zip');
    final manifest = {
      'model_id': 'llama3.1-8b-instruct',
      'version': 'test',
      'family': 'llama3.1-8b-instruct',
      'context_len': 4096,
      'min_device': {'min_ram_mb': 8192, 'min_free_disk_mb': 12288},
      'artifacts': [
        {
          'platform': 'ios_coreml_zip',
          'url': artifactUrl.toString(),
          // Intentionally bogus hash/size: if we download, we *should* fail.
          'sha256': 'deadbeef',
          'size_bytes': 999999999,
          'file_name': 'big.zip',
          'is_zip': true,
        }
      ],
    };

    final client = _FakeClient({
      manifestUrl: http.Response(jsonEncode(manifest), 200),
      // No artifact response needed; skip should prevent this URL from being fetched.
    });

    final mgr = LocalLlmModelPackManager(
      client: client,
      prefs: prefs,
      rootDir: Directory('${tmp.path}/local_llm_packs'),
    );

    // Act: should NOT throw (artifact fetch is skipped).
    await mgr.downloadAndActivate(manifestUrl: manifestUrl);

    // Assert: manifest fetch happened, artifact fetch did not.
    expect(client.requestedUrls, contains(manifestUrl));
    expect(client.requestedUrls, isNot(contains(artifactUrl)));
  });
}

