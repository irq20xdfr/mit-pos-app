import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mit_pos/config.dart';

class ApiService {
  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('${Config.apiEndpoint}/products'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create product');
    }
  }

  static Future<List<Map<String, dynamic>>> sendImageForProductDetection(String imagePath) async {
    var uri = Uri.parse('${Config.apiEndpoint}/products-in-photo');
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();
    
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      Map<String, dynamic> responseMap = jsonDecode(responseBody);
      List<dynamic> items = responseMap['items'];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to detect products from image');
    }
  }

  static Future<List<Map<String, dynamic>>> getInventory() async {
    final response = await http.get(
      Uri.parse('${Config.apiEndpoint}/inventory'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> responseMap = jsonDecode(response.body);
      List<dynamic> inventoryItems = responseMap['inventory'];
      return inventoryItems.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get inventory');
    }
  }

  static Future<Map<String, dynamic>> confirmElement(int elementId) async {
    final response = await http.post(
      Uri.parse('${Config.apiEndpoint}/confirm-element'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'id': elementId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to confirm element');
    }
  }

  static Future<Map<String, dynamic>> addProductToInventory(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('${Config.apiEndpoint}/add-product-to-inventory'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(productData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product to inventory');
    }
  }

  static Future<Map<String, dynamic>> getProductInfo(String barcode) async {
    final response = await http.get(
      Uri.parse('${Config.apiEndpoint}/product-info?barcode=$barcode'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get product info');
    }
  }

  static Future<void> deleteInventoryItem(int itemId) async {
    final response = await http.delete(Uri.parse('${Config.apiEndpoint}/delete-from-inventory?id=$itemId'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete inventory item');
    }
  }

  static Future<Map<String, dynamic>> updateNameAndDescription(Map<String, dynamic> itemData) async {
    final response = await http.post(
      Uri.parse('${Config.apiEndpoint}/update-name-and-description'), 
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(itemData),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update name and description');
    }
    return jsonDecode(response.body);
  }
}
