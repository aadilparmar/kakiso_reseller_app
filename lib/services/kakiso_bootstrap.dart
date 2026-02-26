// lib/services/kakiso_bootstrap.dart
//
// PURPOSE: On app start, pull data from web DB and write to local storage
//          so existing controllers find the data without ANY changes.
//
// HOW IT WORKS:
//   1. Fetch catalog list from plugin → [{id, name, products: [123, 456]}]
//   2. Fetch all products via WC REST API → /wp-json/wc/v3/products?include=1,2,3
//      This returns EXACT same format as ProductModel.fromJson expects!
//   3. Build CatalogueModel objects → write to SharedPreferences 'kakiso_catalogues_v1'
//   4. Fetch customer addresses → write to FlutterSecureStorage 'customer_addresses'
//   5. Fetch business details → write to FlutterSecureStorage 'business_details'
//
// CALL: In main.dart after ApiService().init(), add:
//         KakisoBootstrap.sync();  // fire-and-forget, runs in background

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';
import 'package:kakiso_reseller_app/models/product.dart';

class KakisoBootstrap {
  static Dio? _dio;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Call once from main.dart — runs in background, never blocks UI
  static void sync() {
    _syncAll().catchError((e) {
      debugPrint('[KakisoBootstrap] sync error: $e');
    });
  }

  static Future<Dio> _getClient() async {
    if (_dio != null) return _dio!;

    if (!dotenv.isInitialized) await dotenv.load(fileName: "assets/.env");

    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://kiracelectro.com/kakiso';
    final ck = dotenv.env['CONSUMER_KEY'] ?? '';
    final cs = dotenv.env['CONSUMER_SECRET'] ?? '';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // longer for product fetch
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$ck:$cs'))}',
          'Content-Type': 'application/json',
        },
      ),
    );
    return _dio!;
  }

  static Future<String?> _getUserId() async {
    try {
      final raw = await _secureStorage.read(key: 'userData');
      if (raw == null) return null;
      final data = jsonDecode(raw);
      return (data['userId'] ?? data['id'] ?? '').toString();
    } catch (_) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN SYNC — all in background
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _syncAll() async {
    final uid = await _getUserId();
    if (uid == null || uid.isEmpty || uid == '0') {
      debugPrint('[KakisoBootstrap] No user logged in, skipping sync');
      return;
    }

    debugPrint('[KakisoBootstrap] Starting sync for user $uid...');

    // Run all syncs in parallel
    await Future.wait([
      _syncCatalogs(uid),
      _syncCustomerAddresses(uid),
      _syncBusinessDetails(uid),
    ]);

    debugPrint('[KakisoBootstrap] ✅ All sync complete');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. SYNC CATALOGS
  //    - Fetch catalog list from plugin (IDs only)
  //    - Fetch all products via WC API (correct format)
  //    - Build CatalogueModel JSON → write to SharedPreferences
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _syncCatalogs(String uid) async {
    try {
      final dio = await _getClient();

      // Step 1: Get catalog list from plugin
      final catResp = await dio.get(
        '/wp-json/kakiso/v1/app/catalogs',
        queryParameters: {'user_id': uid},
      );

      if (catResp.data['success'] != true) return;
      final List serverCatalogs = catResp.data['catalogs'] ?? [];
      if (serverCatalogs.isEmpty) {
        debugPrint('[KakisoBootstrap] No catalogs on server');
        return;
      }

      debugPrint(
        '[KakisoBootstrap] Found ${serverCatalogs.length} catalogs on server',
      );

      // Step 2: Collect ALL unique product IDs across all catalogs
      final Set<int> allProductIds = {};
      for (final cat in serverCatalogs) {
        final products = cat['products'];
        if (products is List) {
          for (final pid in products) {
            final id = (pid is int) ? pid : int.tryParse(pid.toString());
            if (id != null && id > 0) allProductIds.add(id);
          }
        }
      }

      if (allProductIds.isEmpty) {
        debugPrint('[KakisoBootstrap] Catalogs have no products');
        // Still save catalog structures (empty catalogs)
        await _writeCatalogsToStorage(serverCatalogs, {});
        return;
      }

      debugPrint(
        '[KakisoBootstrap] Fetching ${allProductIds.length} products via WC API...',
      );

      // Step 3: Fetch products via WC REST API in batches of 100
      // This returns EXACT format that ProductModel.fromJson expects!
      final Map<int, Map<String, dynamic>> productMap = {};
      final idList = allProductIds.toList();

      for (int i = 0; i < idList.length; i += 100) {
        final batch = idList.sublist(i, (i + 100).clamp(0, idList.length));
        final includeStr = batch.join(',');

        try {
          final prodResp = await dio.get(
            '/wp-json/wc/v3/products',
            queryParameters: {
              'include': includeStr,
              'per_page': 100,
              'status': 'publish',
            },
          );

          if (prodResp.data is List) {
            for (final p in prodResp.data) {
              productMap[p['id']] = Map<String, dynamic>.from(p);
            }
          }
        } catch (e) {
          debugPrint('[KakisoBootstrap] Product batch fetch failed: $e');
        }
      }

      debugPrint('[KakisoBootstrap] Fetched ${productMap.length} products');

      // Step 4: Build catalog JSON and save
      await _writeCatalogsToStorage(serverCatalogs, productMap);

      // Step 5: Update CatalogueController if it's already loaded
      _refreshCatalogueController();
    } catch (e) {
      debugPrint('[KakisoBootstrap] Catalog sync failed: $e');
    }
  }

  static Future<void> _writeCatalogsToStorage(
    List serverCatalogs,
    Map<int, Map<String, dynamic>> productMap,
  ) async {
    final List<Map<String, dynamic>> catalogsJson = [];

    for (final cat in serverCatalogs) {
      final List<Map<String, dynamic>> productJsonList = [];
      final products = cat['products'];

      if (products is List) {
        for (final pid in products) {
          final id = (pid is int) ? pid : int.tryParse(pid.toString());
          if (id == null) continue;
          final pData = productMap[id];
          if (pData != null) {
            // Use toJson of ProductModel to ensure round-trip compatibility
            try {
              final pm = ProductModel.fromJson(pData);
              productJsonList.add(pm.toJson());
            } catch (e) {
              debugPrint('[KakisoBootstrap] Product $id parse error: $e');
            }
          }
        }
      }

      catalogsJson.add({
        'id': cat['id']?.toString() ?? '',
        'name': cat['name']?.toString() ?? '',
        'description':
            cat['desc']?.toString() ?? cat['description']?.toString() ?? '',
        'createdAt':
            cat['created']?.toString() ??
            cat['createdAt']?.toString() ??
            DateTime.now().toIso8601String(),
        'products': productJsonList,
      });
    }

    // Write to SharedPreferences — same key CatalogueController reads
    final prefs = await SharedPreferences.getInstance();

    // Merge: keep local catalogs that aren't on server (locally created)
    final existingStr = prefs.getString('kakiso_catalogues_v1');
    if (existingStr != null && existingStr.isNotEmpty) {
      try {
        final existing = jsonDecode(existingStr) as List;
        final serverIds = catalogsJson.map((c) => c['id']).toSet();

        // Add local-only catalogs that don't exist on server
        for (final local in existing) {
          final localId = (local as Map)['id']?.toString() ?? '';
          if (localId.isNotEmpty && !serverIds.contains(localId)) {
            catalogsJson.add(Map<String, dynamic>.from(local));
          }
        }
      } catch (e) {
        debugPrint('[KakisoBootstrap] Existing catalog parse error: $e');
      }
    }

    await prefs.setString('kakiso_catalogues_v1', jsonEncode(catalogsJson));
    debugPrint(
      '[KakisoBootstrap] ✅ Wrote ${catalogsJson.length} catalogs to storage',
    );
  }

  static void _refreshCatalogueController() {
    try {
      if (Get.isRegistered<CatalogueController>()) {
        final ctrl = Get.find<CatalogueController>();
        // Re-read from storage
        SharedPreferences.getInstance().then((prefs) {
          final jsonString = prefs.getString('kakiso_catalogues_v1');
          if (jsonString != null && jsonString.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(jsonString);
            final loaded = decoded
                .map((e) => CatalogueModel.fromJson(e as Map<String, dynamic>))
                .toList();
            ctrl.myCatalogues.assignAll(loaded);
            ctrl.myCatalogues.refresh();
            debugPrint(
              '[KakisoBootstrap] ✅ CatalogueController refreshed with ${loaded.length} catalogs',
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[KakisoBootstrap] Controller refresh failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. SYNC CUSTOMER ADDRESSES
  //    Web DB: reseller_customer_addresses [{id, name, phone, address_1/2/3, city, state, pincode}]
  //    App storage: FlutterSecureStorage 'customer_addresses' [{id, name, phone, addressLine, city, state, country, pincode}]
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _syncCustomerAddresses(String uid) async {
    try {
      final dio = await _getClient();
      final resp = await dio.get(
        '/wp-json/kakiso/v1/app/customer-addresses',
        queryParameters: {'user_id': uid},
      );

      if (resp.data['success'] != true) return;
      final List serverAddrs = resp.data['addresses'] ?? [];
      if (serverAddrs.isEmpty) return;

      // Convert web format → app format
      final List<Map<String, dynamic>> appAddrs = [];
      for (final sa in serverAddrs) {
        final lines = [
          sa['address_1']?.toString() ?? '',
          sa['address_2']?.toString() ?? '',
          sa['address_3']?.toString() ?? '',
        ].where((l) => l.isNotEmpty).toList();

        appAddrs.add({
          'id': sa['id']?.toString() ?? '',
          'name': sa['name']?.toString() ?? '',
          'phone': sa['phone']?.toString() ?? '',
          'addressLine': lines.join(', '),
          'city': sa['city']?.toString() ?? '',
          'state': sa['state']?.toString() ?? '',
          'country': 'India',
          'pincode': sa['pincode']?.toString() ?? '',
        });
      }

      // Merge with existing local addresses
      final existingRaw = await _secureStorage.read(key: 'customer_addresses');
      final List<Map<String, dynamic>> merged = List.from(appAddrs);

      if (existingRaw != null && existingRaw.isNotEmpty) {
        try {
          final existing = jsonDecode(existingRaw) as List;
          final serverIds = appAddrs.map((a) => a['id']).toSet();
          for (final local in existing) {
            final lid = (local as Map)['id']?.toString() ?? '';
            if (lid.isNotEmpty && !serverIds.contains(lid)) {
              merged.add(Map<String, dynamic>.from(local));
            }
          }
        } catch (_) {}
      }

      await _secureStorage.write(
        key: 'customer_addresses',
        value: jsonEncode(merged),
      );
      debugPrint(
        '[KakisoBootstrap] ✅ Synced ${merged.length} customer addresses',
      );
    } catch (e) {
      debugPrint('[KakisoBootstrap] Customer address sync failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. SYNC BUSINESS DETAILS
  //    Web DB: reseller_store_name, reseller_gst, etc.
  //    App storage: FlutterSecureStorage 'business_details'
  //    The address.dart page reads this for business address display
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<void> _syncBusinessDetails(String uid) async {
    try {
      final dio = await _getClient();
      final resp = await dio.get(
        '/wp-json/kakiso/v1/app/business',
        queryParameters: {'user_id': uid},
      );

      if (resp.data['success'] != true) return;
      final d = resp.data['data'];

      // Build the format that address.dart _loadBusinessDetails() expects
      final businessData = {
        'businessName':
            d['reseller_store_name'] ?? d['reseller_business_name'] ?? '',
        'ownerName':
            '${d['billing_first_name'] ?? ''} ${d['billing_last_name'] ?? ''}'
                .trim(),
        'phone': d['billing_phone'] ?? '',
        'email': '', // filled by session
        'address': [
          d['billing_address_1'] ?? '',
          d['billing_address_2'] ?? '',
          d['billing_address_3'] ?? '',
        ].where((s) => s.isNotEmpty).join(', '),
        'city': d['billing_city'] ?? '',
        'state': d['billing_state'] ?? '',
        'country': 'India',
        'pincode': d['billing_postcode'] ?? '',
        // Extra fields for business profile screen
        'gstin': d['reseller_gst'] ?? '',
        'pan': d['reseller_pan'] ?? '',
        'bankName': d['reseller_bank_name'] ?? '',
        'accountNumber': d['reseller_ac_number'] ?? '',
        'ifsc': d['reseller_ifsc'] ?? '',
        'upi': d['reseller_upi'] ?? '',
        'resellerId': d['reseller_unique_id'] ?? '',
        'storeName': d['reseller_store_name'] ?? '',
        'hasSignature': d['has_signature'] ?? false,
        'businessLocked': d['business_locked'] ?? false,
      };

      await _secureStorage.write(
        key: 'business_details',
        value: jsonEncode(businessData),
      );
      debugPrint('[KakisoBootstrap] ✅ Business details synced');
    } catch (e) {
      debugPrint('[KakisoBootstrap] Business sync failed: $e');
    }
  }
}
