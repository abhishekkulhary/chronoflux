import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'github_releases.dart' show githubRepository;

/// Set by CI: `--dart-define=APP_VERSION=<short commit>` for the web build and
/// the release tag for the native builds. Local builds show `dev`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// The GitHub page for [appVersion]: the release for a tag, else the commit.
Uri? get appVersionUrl {
  if (appVersion == 'dev') return null;
  final path = RegExp(r'^v\d').hasMatch(appVersion)
      ? 'releases/tag/$appVersion'
      : 'commit/$appVersion';
  return Uri.parse('https://github.com/$githubRepository/$path');
}

/// "Built with Flutter · 1a2b3c4": which build is running, linked to its
/// commit on GitHub.
class BuildStamp extends StatelessWidget {
  const BuildStamp({super.key, this.style, this.accent});

  /// Base style for the line; defaults to a small muted body style.
  final TextStyle? style;

  /// Colour of the version itself; defaults to the theme's primary colour.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        );
    final url = appVersionUrl;
    final version = Text(
      appVersion,
      style: base?.copyWith(
        color: accent ?? theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Built with Flutter · ', style: base),
        if (url == null)
          version
        else
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: version,
            ),
          ),
      ],
    );
  }
}
