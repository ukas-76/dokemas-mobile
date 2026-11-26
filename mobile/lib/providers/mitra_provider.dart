import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Data model ringkasan status mitra dari GET /api/mitra/status
class MitraStatus {
  final String name;
  final String email;
  final String role;
  final String? verificationStatus; // pending | verified | rejected
  final String? rejectionReason;
  final String? entityType;
  final String? nib;
  final String? nik;
  final String? position;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final MitraDestinationSummary? destination;

  MitraStatus({
    required this.name,
    required this.email,
    required this.role,
    this.verificationStatus,
    this.rejectionReason,
    this.entityType,
    this.nib,
    this.nik,
    this.position,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.destination,
  });

  factory MitraStatus.fromJson(Map<String, dynamic> json) {
    final profile = json['mitra_profile'] as Map<String, dynamic>?;
    final destinations = json['destinations'] as List?;
    MitraDestinationSummary? dest;
    if (destinations != null && destinations.isNotEmpty) {
      dest = MitraDestinationSummary.fromJson(destinations.first as Map<String, dynamic>);
    }
    return MitraStatus(
      name: json['user']?['name'] ?? json['name'] ?? '',
      email: json['user']?['email'] ?? json['email'] ?? '',
      role: json['user']?['role'] ?? json['role'] ?? 'mitra',
      verificationStatus: profile?['verification_status'],
      rejectionReason: profile?['rejection_reason'],
      entityType: profile?['entity_type'],
      nib: profile?['nib'],
      nik: profile?['nik'],
      position: profile?['position'],
      bankName: profile?['bank_name'],
      bankAccountNumber: profile?['bank_account_number'],
      bankAccountHolder: profile?['bank_account_holder'],
      destination: dest,
    );
  }
}

class MitraDestinationSummary {
  final int id;
  final String name;
  final String status; // pending | published | draft | archived
  final String? thumbnailUrl;
  final String? address;
  final String? district;
  final double? price;
  final String? openingHours;
  final double ratingAvg;
  final int ratingCount;
  final List<Map<String, dynamic>> images;
  final List<Map<String, dynamic>> facilities;
  final int? categoryId;
  final String? description;
  final String? csPhone;
  final String? mapsUrl;
  final bool is24Hours;

  MitraDestinationSummary({
    required this.id,
    required this.name,
    required this.status,
    this.thumbnailUrl,
    this.address,
    this.district,
    this.price,
    this.openingHours,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.images = const [],
    this.facilities = const [],
    this.categoryId,
    this.description,
    this.csPhone,
    this.mapsUrl,
    this.is24Hours = false,
  });

  factory MitraDestinationSummary.fromJson(Map<String, dynamic> json) {
    String parseThumb(dynamic raw) {
      final s = (raw ?? '').toString();
      if (s.isEmpty) return '';
      if (s.startsWith('http')) return s.replaceFirst('http://', 'https://');
      return '${ApiConfig.storageBaseUrl}/$s';
    }

    return MitraDestinationSummary(
      id: json['id'],
      name: json['name'] ?? '',
      status: json['status'] ?? 'pending',
      thumbnailUrl: parseThumb(json['thumbnail_url'] ?? json['thumbnail']),
      address: json['address'],
      district: json['district'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      openingHours: json['opening_hours'],
      ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      images: json['images'] != null
          ? List<Map<String, dynamic>>.from(json['images'])
          : [],
      facilities: json['facilities'] != null
          ? List<Map<String, dynamic>>.from(json['facilities'])
          : [],
      categoryId: json['category_id'],
      description: json['description'],
      csPhone: json['cs_phone'],
      mapsUrl: json['maps_url'],
      is24Hours: json['is_24_hours'] == true || json['is_24_hours'] == 1,
    );
  }
}

class MitraReview {
  final int id;
  final String reviewerName;
  final String? reviewerAvatar;
  final double rating;
  final String? comment;
  final String createdAt;
  final String status;

  MitraReview({
    required this.id,
    required this.reviewerName,
    this.reviewerAvatar,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.status,
  });

  factory MitraReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return MitraReview(
      id: json['id'],
      reviewerName: user?['name'] ?? 'Wisatawan',
      reviewerAvatar: user?['avatar'],
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
      status: json['status'] ?? 'public',
    );
  }
}

class MitraProvider with ChangeNotifier {
  MitraStatus? _status;
  List<MitraReview> _reviews = [];
  bool _isLoading = false;
  bool _isReviewLoading = false;
  String? _error;
  String? _reviewError;

  MitraStatus? get status => _status;
  List<MitraReview> get reviews => _reviews;
  bool get isLoading => _isLoading;
  bool get isReviewLoading => _isReviewLoading;
  String? get error => _error;
  String? get reviewError => _reviewError;

  MitraDestinationSummary? get destination => _status?.destination;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse(ApiConfig.mitraStatus),
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _status = MitraStatus.fromJson(data);
      } else {
        _error = 'Gagal memuat status mitra (${resp.statusCode})';
      }
    } catch (e) {
      _error = 'Koneksi gagal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReviews() async {
    final dest = _status?.destination;
    if (dest == null) return;

    _isReviewLoading = true;
    _reviewError = null;
    notifyListeners();

    try {
      final token = await _getToken();
      final url = '${ApiConfig.destinations}/${dest.id}/reviews';
      final resp = await http.get(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = data is List ? data : (data['data'] ?? data['reviews'] ?? []);
        _reviews = (list as List).map((e) => MitraReview.fromJson(e)).toList();
      } else {
        _reviewError = 'Gagal memuat ulasan (${resp.statusCode})';
      }
    } catch (e) {
      _reviewError = 'Koneksi gagal: $e';
    } finally {
      _isReviewLoading = false;
      notifyListeners();
    }
  }

  /// Update destinasi mitra (PUT /api/mitra/destinations/{id})
  Future<String?> updateDestination({
    required int destinationId,
    required Map<String, String> fields,
  }) async {
    try {
      final token = await _getToken();
      final url = '${ApiConfig.mitraDestinations}/$destinationId';
      final resp = await http.put(
        Uri.parse(url),
        headers: ApiConfig.authHeaders(token),
        body: jsonEncode(fields),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        await fetchStatus(); // refresh data
        return null; // sukses
      } else {
        final body = jsonDecode(resp.body);
        return body['message'] ?? 'Gagal menyimpan perubahan';
      }
    } catch (e) {
      return 'Koneksi gagal: $e';
    }
  }

  void clearError() {
    _error = null;
    _reviewError = null;
    notifyListeners();
  }
}
