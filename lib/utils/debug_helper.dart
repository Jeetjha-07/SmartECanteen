import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class DebugHelper {
  // Test if backend is reachable
  static Future<void> testBackendConnection() async {
    print('\n🔍 ========== BACKEND CONNECTION TEST ==========');
    print('Testing: ${ApiService.baseUrl}/restaurants/all\n');

    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/restaurants/all'),
            headers: ApiService.getHeaders(),
          )
          .timeout(const Duration(seconds: 10));

      print('✅ Status Code: ${response.statusCode}');
      print('✅ Content-Type: ${response.headers['content-type']}');
      print('✅ Response length: ${response.body.length}');

      if (response.body.isNotEmpty) {
        print('✅ Response preview: ${response.body.substring(0, 200)}...');
      }

      if (response.statusCode == 200) {
        print('\n✅ Backend is reachable and returning JSON!');
      } else {
        print('\n⚠️ Backend returned status ${response.statusCode}');
        if (response.body.startsWith('<')) {
          print('⚠️ Response is HTML (likely an error page)');
        }
      }
    } catch (e) {
      print('❌ Connection failed: $e');
      print('\nPossible causes:');
      print('  1. Backend server is not running');
      print('  2. Wrong backend URL: ${ApiService.baseUrl}');
      print('  3. Network connectivity issue');
      print('  4. CORS issues');
    }

    print('\n🔍 ========================================\n');
  }

  // Test authentication
  static Future<void> testAuth() async {
    print('\n🔍 ========== AUTH TEST ==========');
    print(
        'JWT Token: ${ApiService.baseUrl.contains('localhost') ? '[LOCAL DEV]' : '[PRODUCTION]'}');

    final headers = ApiService.getHeaders();
    print('Headers being sent:');
    headers.forEach((key, value) {
      if (key == 'Authorization') {
        print('  $key: Bearer [REDACTED]');
      } else {
        print('  $key: $value');
      }
    });

    print('\n🔍 ================================\n');
  }

  // Print debug info
  static void printDebugInfo() {
    print('\n📋 ========== DEBUG INFO ==========');
    print('Backend URL: ${ApiService.baseUrl}');
    print('Is Production: ${ApiService.baseUrl.contains('onrender')}');
    print('Is Local Dev: ${ApiService.baseUrl.contains('localhost')}');
    print('\n📋 ==================================\n');
  }
}
