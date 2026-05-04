import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  /// Mengambil data produk dari OpenFoodFacts berdasarkan barcode (EAN/UPC)
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          // Ambil nama (coba dalam berbagai bahasa atau brand)
          String name = product['product_name'] ?? product['product_name_id'] ?? product['brands'] ?? 'Produk Tak Dikenal';

          double parseNutrient(List<String> keys) {
            for (var key in keys) {
              if (nutriments[key] != null) {
                var value = nutriments[key];
                if (value is num) return value.toDouble();
                if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
              }
            }
            return 0.0;
          }

          double kcal = parseNutrient(['energy-kcal_100g', 'energy-kcal', 'energy-kcal_value', 'energy-kcal_serving']);
          if (kcal == 0.0) {
            double kj = parseNutrient(['energy_100g', 'energy', 'energy_value', 'energy_serving']);
            kcal = kj / 4.184; // Konversi kJ ke kcal
          }

          final protein = parseNutrient(['proteins_100g', 'proteins', 'proteins_value', 'proteins_serving']);
          final carbs = parseNutrient(['carbohydrates_100g', 'carbohydrates', 'carbohydrates_value', 'carbohydrates_serving']);
          final fat = parseNutrient(['fat_100g', 'fat', 'fat_value', 'fat_serving']);

          final String nutriScore = product['nutriscore_grade']?.toString().toUpperCase() ?? '?';

          return {
            'name': name,
            'calories': kcal.round(),
            'protein': protein.round(),
            'carbs': carbs.round(),
            'fats': fat.round(),
            'nutriScore': nutriScore,
            // Kembalikan metadata murni jika sewaktu-waktu mau mengubah serving size
            'isDefault100g': true 
          };
        }
      }
      return null; // Status 0 = Produk tidak ditemukan di database
    } catch (e) {
      print('Error OpenFoodFacts: $e');
      return null;
    }
  }
}
