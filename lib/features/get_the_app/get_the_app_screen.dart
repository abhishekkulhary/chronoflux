import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'github_releases.dart';

/// Lists the native builds from the latest GitHub release. Shown from the web
/// build only (the button that opens it is hidden on native platforms).
class GetTheAppScreen extends StatefulWidget {
  const GetTheAppScreen({super.key, required this.appName, this.releases});

  final String appName;

  /// Injectable for tests; defaults to the live GitHub API.
  final GitHubReleases? releases;

  @override
  State<GetTheAppScreen> createState() => _GetTheAppScreenState();
}

class _GetTheAppScreenState extends State<GetTheAppScreen> {
  late final GitHubReleases _releases = widget.releases ?? GitHubReleases();
  late final Future<LatestRelease?> _latest = _releases.fetchLatest();

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Get ${widget.appName}')),
      body: FutureBuilder<LatestRelease?>(
        future: _latest,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState != ConnectionState.done;
          final release = snapshot.data;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${widget.appName} also runs as a native app. Pick your platform:',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final platform in DownloadPlatform.values)
                    _PlatformTile(
                      platform: platform,
                      release: release,
                      loading: loading,
                      onOpen: _open,
                      releasesUrl: _releases.releasesUrl,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'macOS builds are unsigned: on first launch, allow the app under '
                    'System Settings › Privacy & Security.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _open(_releases.releasesUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(release == null ? 'Releases on GitHub' : 'All releases · latest ${release.tag}'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.platform,
    required this.release,
    required this.loading,
    required this.onOpen,
    required this.releasesUrl,
  });

  final DownloadPlatform platform;
  final LatestRelease? release;
  final bool loading;
  final Future<void> Function(String url) onOpen;
  final String releasesUrl;

  @override
  Widget build(BuildContext context) {
    final asset = release?.assets[platform];
    final isCurrent = DownloadPlatform.current == platform;
    final status = loading
        ? 'Checking the latest release…'
        : asset != null
            ? '${release!.tag} · ${asset.sizeLabel}'
            : 'Not published yet';

    final button = asset != null && isCurrent
        ? FilledButton.icon(
            onPressed: () => onOpen(asset.downloadUrl),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          )
        : OutlinedButton.icon(
            onPressed: loading ? null : () => onOpen(asset?.downloadUrl ?? releasesUrl),
            icon: Icon(asset != null ? Icons.download : Icons.open_in_new),
            label: Text(asset != null ? 'Download' : 'Releases'),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(platform.icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(platform.label, style: Theme.of(context).textTheme.titleMedium),
                      if (isCurrent) const Chip(label: Text('Your device'), visualDensity: VisualDensity.compact),
                    ],
                  ),
                  Text('${platform.format} · $status', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            button,
          ],
        ),
      ),
    );
  }
}
