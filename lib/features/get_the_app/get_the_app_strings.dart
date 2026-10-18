import 'package:flutter/widgets.dart';

/// Text for the "Get the app" button and screen, in English and German.
/// Picked from the app's current locale; anything else falls back to English.
class GetTheAppStrings {
  const GetTheAppStrings._(this._de);

  final bool _de;

  static GetTheAppStrings of(BuildContext context) =>
      GetTheAppStrings._(Localizations.maybeLocaleOf(context)?.languageCode == 'de');

  String get getTheApp => _de ? 'App herunterladen' : 'Get the app';
  String title(String appName) => _de ? '$appName herunterladen' : 'Get $appName';
  String intro(String appName) => _de
      ? '$appName gibt es auch als native App. Wähle deine Plattform:'
      : '$appName also runs as a native app. Pick your platform:';
  String get checking => _de ? 'Neueste Version wird geprüft …' : 'Checking the latest release…';
  String get notPublished => _de ? 'Noch nicht veröffentlicht' : 'Not published yet';
  String get yourDevice => _de ? 'Dein Gerät' : 'Your device';
  String get download => _de ? 'Herunterladen' : 'Download';
  String get releases => 'Releases';
  String get macNote => _de
      ? 'macOS-Builds sind nicht signiert: Erlaube die App beim ersten Start unter '
          'Systemeinstellungen › Datenschutz & Sicherheit.'
      : 'macOS builds are unsigned: on first launch, allow the app under '
          'System Settings › Privacy & Security.';
  String get releasesOnGitHub => _de ? 'Releases auf GitHub' : 'Releases on GitHub';
  String allReleases(String tag) => _de ? 'Alle Releases · neueste $tag' : 'All releases · latest $tag';
}
