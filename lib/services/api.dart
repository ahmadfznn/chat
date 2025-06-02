import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Api {
  // final String _username = dotenv.env['USERNAME']!;
  // final String _password = dotenv.env['PW2']!;
  String baseUrl = dotenv.env['API_URL']!;

  Future<Map<String, dynamic>> get(
      Map<String, dynamic> data, String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<http.Response> post(Map<String, dynamic> data, String endpoint,
      [Map<String, dynamic>? header = const {}]) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ...header!},
      body: jsonEncode(data),
    );

    return response;
  }
}
