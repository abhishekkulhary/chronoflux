import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:chronoflux/features/get_the_app/get_the_app_screen.dart';
import 'package:chronoflux/features/get_the_app/github_releases.dart';

GitHubReleases _releases(int status, [Map<String, dynamic>? body]) => GitHubReleases(
      repository: 'owner/app',
      client: MockClient((_) async => http.Response(jsonEncode(body ?? {}), status)),
    );

Map<String, dynamic> _release(List<String> names) => {
      'tag_name': 'v1.2.0',
      'published_at': '2026-10-18T12:00:00Z',
      'assets': [
        for (final name in names)
          {'name': name, 'browser_download_url': 'https://example.com/$name', 'size': 1048576},
      ],
    };

void main() {
  test('maps release assets to platforms and ignores the rest', () {
    final release = LatestRelease.fromJson(_release([
      'chronoflux-android.apk',
      'chronoflux-windows-x64.zip',
      'chronoflux-macos.dmg',
      'chronoflux-linux-x64.tar.gz',
      'SHA256SUMS.txt',
    ]));
    expect(release.assets.keys, unorderedEquals(DownloadPlatform.values));
    expect(release.assets[DownloadPlatform.android]!.sizeLabel, '1.0 MB');
  });

  test('a missing release is null, not an error', () async {
    expect(await _releases(404).fetchLatest(), isNull);
  });

  testWidgets('screen falls back to the releases page without a release', (tester) async {
    await tester.pumpWidget(MaterialApp(home: GetTheAppScreen(appName: 'App', releases: _releases(404))));
    await tester.pumpAndSettle();
    expect(find.text('Get App'), findsOneWidget);
    expect(find.textContaining('Not published yet'), findsNWidgets(DownloadPlatform.values.length));
  });

  testWidgets('screen lists downloads from the latest release', (tester) async {
    final releases = _releases(200, _release(['chronoflux-android.apk', 'chronoflux-linux-x64.tar.gz']));
    await tester.pumpWidget(MaterialApp(home: GetTheAppScreen(appName: 'App', releases: releases)));
    await tester.pumpAndSettle();
    expect(find.textContaining('v1.2.0 · 1.0 MB'), findsNWidgets(2));
    expect(find.textContaining('Not published yet'), findsNWidgets(2));
  });
}
