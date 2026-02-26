// lib/services/sync_service.dart
//
// PUSH only — syncs local changes to web DB.
// Bootstrap handles the PULL direction.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  Dio? _dio;
  Timer? _catTimer;
  Timer? _wlTimer;
  Timer? _addrTimer;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<Dio> get _client async {
    if (_dio != null) return _dio!;
    if (!dotenv.isInitialized) await dotenv.load(fileName: "assets/.env");
    final base = dotenv.env['BASE_URL'] ?? 'https://kiranelectro.com/kakiso';
    final ck = dotenv.env['CONSUMER_KEY'] ?? '';
    final cs = dotenv.env['CONSUMER_SECRET'] ?? '';
    _dio = Dio(
      BaseOptions(
        baseUrl: base,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$ck:$cs'))}',
          'Content-Type': 'application/json',
        },
      ),
    );
    return _dio!;
  }

  Future<String?> _uid() async {
    try {
      final raw = await _storage.read(key: 'userData');
      if (raw == null) return null;
      final d = jsonDecode(raw);
      return (d['userId'] ?? d['id'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  // ── CATALOGS (debounced push) ──────────────────────────────────────────────
  void syncCatalogs(List<Map<String, dynamic>> catalogs) {
    _catTimer?.cancel();
    _catTimer = Timer(
      const Duration(seconds: 3),
      () => _pushCatalogs(catalogs),
    );
  }

  Future<void> _pushCatalogs(List<Map<String, dynamic>> catalogs) async {
    try {
      final uid = await _uid();
      if (uid == null || uid.isEmpty) return;
      final dio = await _client;
      await dio.post(
        '/wp-json/kakiso/v1/app/catalogs',
        queryParameters: {'user_id': uid},
        data: {'catalogs': catalogs},
      );
      debugPrint('[Sync] ✅ Catalogs pushed (${catalogs.length})');
    } catch (e) {
      debugPrint('[Sync] ⚠️ Catalog push failed: $e');
    }
  }

  // ── WISHLIST (debounced push) ──────────────────────────────────────────────
  void syncWishlist(List<Map<String, dynamic>> items) {
    _wlTimer?.cancel();
    _wlTimer = Timer(const Duration(seconds: 3), () => _pushWishlist(items));
  }

  Future<void> _pushWishlist(List<Map<String, dynamic>> items) async {
    try {
      final uid = await _uid();
      if (uid == null || uid.isEmpty) return;
      final dio = await _client;
      await dio.post(
        '/wp-json/kakiso/v1/app/wishlist',
        queryParameters: {'user_id': uid},
        data: {'items': items},
      );
      debugPrint('[Sync] ✅ Wishlist pushed');
    } catch (e) {
      debugPrint('[Sync] ⚠️ Wishlist push failed: $e');
    }
  }

  // ── CUSTOMER ADDRESSES (debounced push) ────────────────────────────────────
  void syncCustomerAddresses(List<Map<String, dynamic>> addrs) {
    _addrTimer?.cancel();
    _addrTimer = Timer(const Duration(seconds: 2), () => _pushAddresses(addrs));
  }

  Future<void> _pushAddresses(List<Map<String, dynamic>> addrs) async {
    try {
      final uid = await _uid();
      if (uid == null || uid.isEmpty) return;
      final dio = await _client;
      await dio.post(
        '/wp-json/kakiso/v1/app/customer-addresses',
        queryParameters: {'user_id': uid},
        data: {'addresses': addrs},
      );
      debugPrint('[Sync] ✅ Addresses pushed (${addrs.length})');
    } catch (e) {
      debugPrint('[Sync] ⚠️ Address push failed: $e');
    }
  }

  // ── READ-ONLY ENDPOINTS ────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchInvoices(String orderId) async {
    try {
      final uid = await _uid();
      if (uid == null) return [];
      final dio = await _client;
      final r = await dio.get(
        '/wp-json/kakiso/v1/app/orders/$orderId/invoices',
        queryParameters: {'user_id': uid},
      );
      if (r.data['success'] == true)
        return List<Map<String, dynamic>>.from(r.data['invoices'] ?? []);
    } catch (e) {
      debugPrint('[Sync] Invoice fetch: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchTracking(String orderId) async {
    try {
      final uid = await _uid();
      if (uid == null) return [];
      final dio = await _client;
      final r = await dio.get(
        '/wp-json/kakiso/v1/app/orders/$orderId/tracking',
        queryParameters: {'user_id': uid},
      );
      if (r.data['success'] == true)
        return List<Map<String, dynamic>>.from(r.data['items'] ?? []);
    } catch (e) {
      debugPrint('[Sync] Tracking fetch: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> fetchEarnings() async {
    try {
      final uid = await _uid();
      if (uid == null) return null;
      final dio = await _client;
      final r = await dio.get(
        '/wp-json/kakiso/v1/app/earnings',
        queryParameters: {'user_id': uid},
      );
      if (r.data['success'] == true) return r.data['data'];
    } catch (e) {
      debugPrint('[Sync] Earnings fetch: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchDashboard() async {
    try {
      final uid = await _uid();
      if (uid == null) return null;
      final dio = await _client;
      final r = await dio.get(
        '/wp-json/kakiso/v1/app/dashboard',
        queryParameters: {'user_id': uid},
      );
      if (r.data['success'] == true) return r.data['data'];
    } catch (e) {
      debugPrint('[Sync] Dashboard fetch: $e');
    }
    return null;
  }
}
