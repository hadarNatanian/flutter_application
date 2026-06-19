import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const _apiKey = 'bd5e378503939ddaee76f12ad7a97608';

  static Future<Map<String, dynamic>?> getWeather(String city) async {
    try {
      final url =
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$_apiKey&units=metric&lang=he';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
