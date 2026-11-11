const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://bookcut.api.adsocidm.com/api',
);

String get apiOrigen {
  final uri = Uri.parse(apiUrl);
  if (uri.scheme.isEmpty || uri.host.isEmpty) return '';
  final puerto = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://${uri.host}$puerto';
}
