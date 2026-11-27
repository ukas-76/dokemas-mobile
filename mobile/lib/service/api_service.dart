import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination.dart';
import '../models/category.dart';
import '../models/facility.dart';
import '../models/review.dart';
import '../config/api_config.dart';

class ApiService {
  Future<List<Destination>> fetchDestinations() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.destinations),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> body;

        if (decodedData is Map<String, dynamic>) {
          body = decodedData['data'] ?? [];
        } else if (decodedData is List) {
          body = decodedData;
        } else {
          throw Exception('Format data tidak dikenali');
        }

        return body.map((dynamic item) => Destination.fromJson(item)).toList();
      } else {
        throw Exception(
          'Gagal mengambil data dari server (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<List<Category>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.categories),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Category.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data kategori');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<List<Facility>> fetchFacilities() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.facilities),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Facility.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data fasilitas');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<List<Review>> fetchMyReviews(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myReviews),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> body;

        if (decodedData is Map<String, dynamic>) {
          body = decodedData['data'] ?? [];
        } else if (decodedData is List) {
          body = decodedData;
        } else {
          throw Exception('Format data tidak dikenali');
        }

        return body.map((dynamic item) => Review.fromJson(item)).toList();
      } else {
        throw Exception(
          'Gagal mengambil data ulasan (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<List<Review>> fetchDestinationReviews(int destinationId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.destinations}/$destinationId/reviews'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> body;

        if (decodedData is Map<String, dynamic>) {
          body = decodedData['data'] ?? [];
        } else if (decodedData is List) {
          body = decodedData;
        } else {
          throw Exception('Format data tidak dikenali');
        }

        return body.map((dynamic item) => Review.fromJson(item)).toList();
      } else {
        throw Exception(
          'Gagal mengambil data ulasan (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<Review> postReview({
    required String token,
    required int destinationId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.destinations}/$destinationId/reviews'),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedData = jsonDecode(response.body);
        
        dynamic reviewData;
        if (decodedData is Map<String, dynamic>) {
          reviewData = decodedData['data'] ?? decodedData['review'] ?? decodedData;
        } else {
          reviewData = decodedData;
        }

        return Review.fromJson(reviewData);
      } else {
        final decoded = jsonDecode(response.body);
        throw Exception(decoded['message'] ?? 'Gagal mengirim ulasan');
      }
    } catch (e) {
      throw Exception('Gagal terhubung ke server backend: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNearbyAccommodations(
    int destinationId, {
    double radius = 2.0,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.destinations}/$destinationId/nearby-accommodations?radius=$radius',
      );
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Destination?> fetchDestinationDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.destinations}/$id'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic> && decoded.containsKey('data')
            ? decoded['data']
            : decoded;
        return Destination.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}