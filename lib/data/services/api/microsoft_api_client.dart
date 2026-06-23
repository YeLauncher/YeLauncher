import 'dart:async';
import 'dart:convert';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:yelauncher/utilities/result.dart';
import 'package:yelauncher/data/services/api/models/minecraft_profile_api_model.dart';

class MicrosoftApiClient {
  final String authorizationEndpoint = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize";
  final String tokenEndpoint = "https://login.microsoftonline.com/consumers/oauth2/v2.0/token";
  final String redirectUrl = "http://localhost:8080/callback";
  final String clientId = "77b1105a-a596-4ca3-b463-e05ac047667a";
  final Logger _log = Logger('MicrosoftApiClient');

  Future<Result<String>> getAccessToken() async {
    final authenticationUrl = Uri.parse(authorizationEndpoint).replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUrl,
      'scope': 'XboxLive.signin offline_access',
    });
    final resultUrl = await FlutterWebAuth2.authenticate(
      url: authenticationUrl.normalizePath().toString(),
      callbackUrlScheme: 'http', // The scheme it listens for on Windows/Linux
      // NOTE: If using macOS with a custom scheme, change this to 'com.example.myapp'
    );

    // 3. Extract the authorization code from the callback URL
    final code = Uri.parse(resultUrl).queryParameters['code'];

    if (code != null) {
      // 4. Exchange the code for an Access Token
      var token = await _exchangeCodeForToken(code);
      if (token != null) {
        return Result.success(token);
      }
    }
    return Result.failure(Exception("The authentication process was cancelled or failed."));
  }

  Future<Result<(String xblToken, String userHash)>> exchangeXblToken(String accessToken) async {
    try {
      final uri = Uri.parse('https://user.auth.xboxlive.com/user/authenticate');
      final body = jsonEncode({
        'Properties': {
          'AuthMethod': 'RPS',
          'SiteName': 'user.auth.xboxlive.com',
          'RpsTicket': 'd=$accessToken'
        },
        'RelyingParty': 'http://auth.xboxlive.com',
        'TokenType': 'JWT'
      });

      _log.fine('Exchange XBL token request to $uri');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        _log.warning('Failed to exchange XBL token: ${response.statusCode} ${response.body}');
        return Result.failure(Exception('Failed to exchange XBL token: ${response.statusCode}'));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['Token'] as String?;
      String? userHash;
      try {
        final displayClaims = data['DisplayClaims'] as Map<String, dynamic>?;
        final xui = displayClaims?['xui'] as List<dynamic>?;
        if (xui != null && xui.isNotEmpty) {
          userHash = (xui.first as Map<String, dynamic>)['uhs'] as String?;
        }
      } catch (_) {
        userHash = null;
      }

      if (token == null || userHash == null) {
        _log.warning('Malformed XBL response: missing Token or user hash: ${response.body}');
        return Result.failure(Exception('Malformed XBL response'));
      }

      _log.fine('Obtained XBL token and user hash');
      return Result.success((token, userHash));
    } on Exception catch (e) {
      _log.severe('exchangeXblToken error: $e');
      return Result.failure(Exception('exchangeXblToken failed: $e'));
    }
  }

  Future<Result<String>> exchangeXstsToken(String xblToken, String userHash) async {
    try {
      final uri = Uri.parse('https://xsts.auth.xboxlive.com/xsts/authorize');
      final body = jsonEncode({
        'Properties': {
          'SandboxId': 'RETAIL',
          'UserTokens': [xblToken],
        },
        'RelyingParty': 'rp://api.minecraftservices.com/',
        'TokenType': 'JWT'
      });

      _log.fine('Exchange XSTS token request to $uri');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        _log.warning('Failed to exchange XSTS token: ${response.statusCode} ${response.body}');
        return Result.failure(Exception('Failed to exchange XSTS token: ${response.statusCode}'));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['Token'] as String?;
      String? uhs;
      try {
        final displayClaims = data['DisplayClaims'] as Map<String, dynamic>?;
        final xui = displayClaims?['xui'] as List<dynamic>?;
        if (xui != null && xui.isNotEmpty) {
          uhs = (xui.first as Map<String, dynamic>)['uhs'] as String?;
        }
      } catch (_) {
        uhs = null;
      }

      if (token == null) {
        _log.warning('Malformed XSTS response: missing Token: ${response.body}');
        return Result.failure(Exception('Malformed XSTS response'));
      }

      if (uhs != null && userHash.isNotEmpty && uhs != userHash) {
        _log.warning('XSTS returned uhs "$uhs" which does not match expected userHash "$userHash"');
      }

      _log.fine('Obtained XSTS token');
      return Result.success(token);
    } on Exception catch (e) {
      _log.severe('exchangeXstsToken error: $e');
      return Result.failure(Exception('exchangeXstsToken failed: $e'));
    }
  }

  Future<Result<String>> exchangeMinecraftToken(String xstsToken, String userHash) async {
    try {
      final uri = Uri.parse('https://api.minecraftservices.com/authentication/login_with_xbox');
      final identity = 'XBL3.0 x=$userHash;$xstsToken';
      final body = jsonEncode({'identityToken': identity});

      _log.fine('Exchange Minecraft token request to $uri');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        _log.warning('Failed to exchange Minecraft token: ${response.statusCode} ${response.body}');
        return Result.failure(Exception('Failed to exchange Minecraft token: ${response.statusCode}'));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final mcToken = data['access_token'] as String? ?? data['token'] as String?;
      if (mcToken == null) {
        _log.warning('Malformed Minecraft auth response: ${response.body}');
        return Result.failure(Exception('Malformed Minecraft auth response'));
      }

      _log.fine('Obtained Minecraft access token');
      return Result.success(mcToken);
    } on Exception catch (e) {
      _log.severe('exchangeMinecraftToken error: $e');
      return Result.failure(Exception('exchangeMinecraftToken failed: $e'));
    }
  }

  Future<Result<MinecraftProfileApiModel>> getProfile(String minecraftAccessToken) async {
    try {
      final uri = Uri.parse('https://api.minecraftservices.com/minecraft/profile');
      _log.fine('Requesting Minecraft profile from $uri');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $minecraftAccessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        _log.warning('Failed to fetch Minecraft profile: ${response.statusCode} ${response.body}');
        return Result.failure(Exception('Failed to fetch Minecraft profile: ${response.statusCode}'));
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = MinecraftProfileApiModel.fromJson(data);
      return Result.success(profile);
    } on Exception catch (e) {
      _log.severe('getProfile error: $e');
      return Result.failure(Exception('getProfile failed: $e'));
    }
  }

  Future<String?> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'code': code,
      },
    );

    if (response.statusCode == 200) {
      final tokens = jsonDecode(response.body);
      _log.info('Access Token: ${tokens['access_token']}');
      _log.info('ID Token: ${tokens['id_token']}');

      return tokens['access_token'];
    } else {
      _log.info('Failed to exchange code: ${response.body}');
    }
    return null;
  }
}