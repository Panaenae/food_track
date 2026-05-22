import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:food_track/models/food_item.dart';

class FoodApiService {
  /// The base URL for the Open Food Facts Search API
  static const String _baseUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    // 1. Construct the URL with parameters
    // We ask for JSON format, a simple search, and our search terms
    final url = Uri.parse('$_baseUrl?search_terms=$query&search_simple=1&action=process&json=1&page_size=20');

    try {
      // 2. Make the HTTP GET request
      final response = await http.get(url);

      // 3. Check if the request was successful (Status Code 200)
      if (response.statusCode == 200) {
        // 4. Decode the raw string (JSON) into a Map
        final data = json.decode(response.body);
        final List products = data['products'] ?? [];

        // 5. Map the API results to our FoodItem model
        return products.map((json) {
          final nutriments = json['nutriments'] ?? {};
          
          // Open Food Facts usually provides values per 100g
          return FoodItem(
            id: json['_id'] ?? '',
            name: json['product_name'] ?? 'Unknown Food',
            // Get calories, default to 0 if missing
            calories: (nutriments['energy-kcal_100g'] as num? ?? 0).toInt(),
            servingLabel: json['serving_size'] ?? '100g',
            category: json['categories']?.split(',').first,
            protein: (nutriments['proteins_100g'] as num?)?.toInt(),
            carbs: (nutriments['carbohydrates_100g'] as num?)?.toInt(),
            fat: (nutriments['fat_100g'] as num?)?.toInt(),
          );
        }).toList();
      } else {
        throw Exception('Failed to load foods');
      }
    } catch (e) {
      // If there's a network error or parsing error
      print('Error searching foods: $e');
      return [];
    }
  }
}
