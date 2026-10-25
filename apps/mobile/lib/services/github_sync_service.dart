import 'dart:convert';

import 'package:http/http.dart' as http;

/// Where the encrypted blob lives on GitHub.
class GitHubConfig {
  final String token;
  final String owner;
  final String repo;
  final String path;
  final String branch;

  const GitHubConfig({
    required this.token,
    required this.owner,
    required this.repo,
    this.path = 'data.enc',
    this.branch = 'main',
  });
}

/// A file fetched from GitHub: its decoded text content plus the blob `sha`
/// needed to update it.
class RemoteFile {
  final String content;
  final String sha;
  const RemoteFile({required this.content, required this.sha});
}

class GitHubException implements Exception {
  final int statusCode;
  final String message;
  const GitHubException(this.statusCode, this.message);
  @override
  String toString() => 'GitHubException($statusCode): $message';
}

/// Minimal GitHub Contents API client: read and write a single file.
class GitHubSyncService {
  final http.Client _client;
  GitHubSyncService({http.Client? client}) : _client = client ?? http.Client();

  Uri _contentsUri(GitHubConfig cfg) => Uri.https(
    'api.github.com',
    '/repos/${cfg.owner}/${cfg.repo}/contents/${cfg.path}',
  );

  Map<String, String> _headers(GitHubConfig cfg) => {
    'Authorization': 'Bearer ${cfg.token}',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  /// Fetches the file, or null if it doesn't exist yet (first sync).
  Future<RemoteFile?> getFile(GitHubConfig cfg) async {
    final response = await _client.get(
      _contentsUri(cfg).replace(queryParameters: {'ref': cfg.branch}),
      headers: _headers(cfg),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw GitHubException(response.statusCode, response.body);
    }

    final json = jsonDecode(response.body) as Map<String, Object?>;
    // Contents API returns base64 with embedded newlines.
    final rawB64 = (json['content'] as String).replaceAll('\n', '');
    return RemoteFile(
      content: utf8.decode(base64Decode(rawB64)),
      sha: json['sha'] as String,
    );
  }

  /// Creates or updates the file. Pass the current [sha] when updating.
  Future<void> putFile(
    GitHubConfig cfg,
    String content, {
    String? sha,
    String message = 'Sync Money Planner data',
  }) async {
    final response = await _client.put(
      _contentsUri(cfg),
      headers: {..._headers(cfg), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'content': base64Encode(utf8.encode(content)),
        'branch': cfg.branch,
        'sha': ?sha,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw GitHubException(response.statusCode, response.body);
    }
  }

  void dispose() => _client.close();
}
