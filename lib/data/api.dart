import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Error dari API, dengan pesan yang siap ditampilkan ke pengguna.
class ApiException implements Exception {
  ApiException(this.message, [this.status = 0]);
  final String message;
  final int status;
  @override
  String toString() => message;
}

/// Klien API MaggotKu.
class Api {
  Api(this.token, {http.Client? client, this.baseUrl = defaultBaseUrl})
    : _c = client ?? http.Client();

  static const defaultBaseUrl = 'https://appsmobiledeveloper.my.id/api-maggot';
  static const _timeout = Duration(seconds: 25);

  String? token;
  final String baseUrl;
  final http.Client _c;

  Uri _u(String path) => Uri.parse('$baseUrl$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path) =>
      _send(() => _c.get(_u(path), headers: _headers));
  Future<dynamic> post(String path, [Object? body]) => _send(
    () => _c.post(_u(path), headers: _headers, body: jsonEncode(body ?? {})),
  );
  Future<dynamic> put(String path, Object body) =>
      _send(() => _c.put(_u(path), headers: _headers, body: jsonEncode(body)));
  Future<dynamic> delete(String path) =>
      _send(() => _c.delete(_u(path), headers: _headers));

  /// Upload foto (multipart, field "foto").
  Future<dynamic> upload(
    String path,
    String filePath,
    Map<String, String> fields,
  ) => _send(() async {
    final req = http.MultipartRequest('POST', _u(path))
      ..fields.addAll(fields)
      ..files.add(
        await http.MultipartFile.fromPath(
          'foto',
          filePath,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    return http.Response.fromStream(await _c.send(req));
  });

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response r;
    try {
      r = await request().timeout(_timeout);
    } on TimeoutException {
      throw ApiException('Koneksi lambat, coba lagi sebentar ya.');
    } catch (_) {
      throw ApiException('Tidak ada koneksi internet.');
    }
    dynamic json;
    try {
      json = jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {}
    if (r.statusCode >= 200 && r.statusCode < 300) return json;
    final msg = json is Map && json['error'] is String
        ? json['error'] as String
        : r.statusCode == 503
        ? 'Server sedang tidak aktif, coba lagi nanti.'
        : 'Server bermasalah (${r.statusCode}).';
    throw ApiException(msg, r.statusCode);
  }
}

/// Format tanggal untuk API: "2026-11-12T10:30:00".
String apiDate(DateTime d) => d.toIso8601String().substring(0, 19);
