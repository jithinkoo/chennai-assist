/// Where the Chennai Assist website (and its API) lives.
///
/// Override when running against a local server, e.g.:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000
const String apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://city-help.onrender.com',
);
