import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:schoolnet/utils/colors.dart';

class ApiService {
  static final storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await storage.read(key: "auth_token");
  }

  static Future<bool> _refreshToken() async {
    final refreshToken = await storage.read(key: "refresh_token");
    if (refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse("${generalUrl}api/auth/refresh"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await storage.write(key: "auth_token", value: data["token"]);
        return true;
      }
    } catch (e) {
      debugPrint("Error al refrescar token: $e.");
    }
    return false;
  }

  static Future<http.Response> request(
      String endpoint, {
        String method = "GET",
        Map<String, String>? headers,
        dynamic body,
      }) async {
    String? token = await _getToken();
    final defaultHeaders = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    http.Response response;

    try {
      final uri = Uri.parse("$generalUrl$endpoint");

      switch (method.toUpperCase()) {
        case "POST":
          response = await http.post(uri,
              headers: {...defaultHeaders, ...?headers},
              body: body != null ? json.encode(body) : null);
          break;
        case "PUT":
          response = await http.put(uri,
              headers: {...defaultHeaders, ...?headers},
              body: body != null ? json.encode(body) : null);
          break;
        case "DELETE":
          response = await http.delete(uri,
              headers: {...defaultHeaders, ...?headers});
          break;
        default: // GET
          response = await http.get(uri, headers: {...defaultHeaders, ...?headers});
      }

      // Refrescar si el token vence
      if (response.statusCode == 401) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          token = await _getToken();
          final retryHeaders = {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
            ...?headers,
          };

          // repetir la petición
          switch (method.toUpperCase()) {
            case "POST":
              response = await http.post(uri,
                  headers: retryHeaders,
                  body: body != null ? json.encode(body) : null);
              break;
            case "PUT":
              response = await http.put(uri,
                  headers: retryHeaders,
                  body: body != null ? json.encode(body) : null);
              break;
            case "DELETE":
              response = await http.delete(uri, headers: retryHeaders);
              break;
            default:
              response = await http.get(uri, headers: retryHeaders);
          }
        }
      }
      return response;
    } catch (e) {
      debugPrint("Error en request: $e.");
      rethrow;
    }
  }
}
