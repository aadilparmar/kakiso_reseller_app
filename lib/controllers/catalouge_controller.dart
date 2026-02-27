// lib/controllers/catalouge_controller.dart
//
// v6: FIXED — Polling pauses during server push to prevent overwriting
//
// The bug was: optimistic UI update → 5s poll fires → server hasn't
// processed yet → poll overwrites optimistic update with stale data.
//
// Fix: _pushLock prevents polling from fetching while a push is active.
// After push completes + small delay, a forced fetch confirms the state.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

// =============================================================================
// MODEL
// =============================================================================

class CatalogueModel {
  final String id;
  String name;
  String description;
  DateTime createdAt;
  List<ProductModel> products;

  CatalogueModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.products,
  });

  factory CatalogueModel.fromJson(Map<String, dynamic> json) {
    return CatalogueModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      products: (json['products'] as List<dynamic>? ?? [])
          .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'products': products.map((p) => p.toJson()).toList(),
    };
  }

  Map<String, dynamic> toServerJson() {
    return {
      'id': id,
      'name': name,
      'desc': description,
      'created': createdAt.toIso8601String(),
      'product_ids': products.map((p) => p.id).toList(),
    };
  }

  CatalogueModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<ProductModel>? products,
  }) {
    return CatalogueModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      products: products ?? this.products,
    );
  }
}

// =============================================================================
// CONTROLLER
// =============================================================================

class CatalogueController extends GetxController with WidgetsBindingObserver {
  // ── Observables ──
  final RxList<CatalogueModel> myCatalogues = <CatalogueModel>[].obs;
  final RxBool isSyncing = false.obs;
  final RxBool isLoaded = false.obs;

  // ── Internal state ──
  final Map<int, ProductModel> _productCache = {};
  Timer? _pollTimer;
  bool _isFetching = false;
  String? _cachedUserId;
  bool _tabActive = false;

  // ── Push lock: prevents polling from overwriting optimistic updates ──
  int _activePushes = 0;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _forceFetch();
    _startPolling(fast: false);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceFetch();
      _startPolling(fast: _tabActive);
    } else if (state == AppLifecycleState.paused) {
      _pollTimer?.cancel();
    }
  }

  // =========================================================================
  // POLLING
  // =========================================================================

  void _startPolling({required bool fast}) {
    _pollTimer?.cancel();
    final duration = fast
        ? const Duration(seconds: 5)
        : const Duration(seconds: 30);
    _pollTimer = Timer.periodic(duration, (_) {
      // CRITICAL: Skip poll if a push is in progress
      if (_activePushes > 0) {
        debugPrint('CatalogSync: Poll skipped — push in progress');
        return;
      }
      _fetchFromServer();
    });
  }

  // =========================================================================
  // UI TRIGGERS
  // =========================================================================

  void onCatalogTabOpened() {
    _tabActive = true;
    if (_activePushes == 0) _forceFetch();
    _startPolling(fast: true);
  }

  void onCatalogTabClosed() {
    _tabActive = false;
    _startPolling(fast: false);
  }

  Future<void> refreshFromServer() => _forceFetch();

  // =========================================================================
  // PUBLIC API — UNCHANGED SIGNATURES
  // =========================================================================

  CatalogueModel? getById(String id) {
    try {
      return myCatalogues.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> get catalogueNames => myCatalogues
      .map((c) => c.name.isEmpty ? 'Untitled Catalogue' : c.name)
      .toList();

  // ── CREATE ──
  void createCatalogue(String name, String description) {
    final id = _genId();
    final cat = CatalogueModel(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      products: [],
    );
    myCatalogues.add(cat);
    myCatalogues.refresh();

    _doPush(() async {
      final uid = await _uid();
      if (uid == null) return;
      await ApiService().createCatalogOnServer(
        userId: uid,
        catalogId: id,
        name: name,
        desc: description,
      );
    });
  }

  void createCatalogueAndAddProduct(
    String name,
    ProductModel product, {
    String description = '',
  }) {
    final id = _genId();
    _productCache[product.id] = product;
    final cat = CatalogueModel(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime.now(),
      products: [product],
    );
    myCatalogues.add(cat);
    myCatalogues.refresh();

    _doPush(() async {
      final uid = await _uid();
      if (uid == null) return;
      await ApiService().createCatalogOnServer(
        userId: uid,
        catalogId: id,
        name: name,
        desc: description,
        productIds: [product.id],
      );
    });
  }

  // ── DELETE ──
  void deleteCatalogue(String id) {
    myCatalogues.removeWhere((c) => c.id == id);
    myCatalogues.refresh();

    _doPush(() async {
      final uid = await _uid();
      if (uid == null) return;
      await ApiService().deleteCatalogOnServer(userId: uid, catalogId: id);
    });
  }

  // ── ADD PRODUCT ──
  void addProductToCatalogue(String catalogueId, ProductModel product) {
    final idx = myCatalogues.indexWhere((c) => c.id == catalogueId);
    if (idx == -1) return;
    final cat = myCatalogues[idx];
    if (cat.products.any((p) => p.id == product.id)) return;

    cat.products.add(product);
    myCatalogues[idx] = cat.copyWith(
      products: List<ProductModel>.from(cat.products),
    );
    myCatalogues.refresh();
    _productCache[product.id] = product;

    _doPush(() async {
      final uid = await _uid();
      if (uid == null) return;
      await ApiService().updateCatalogOnServer(
        userId: uid,
        catalogId: catalogueId,
        action: 'add_product',
        productId: product.id,
      );
    });
  }

  void addProductToExistingCatalogueByName(String name, ProductModel product) {
    try {
      final cat = myCatalogues.firstWhere((c) => c.name == name);
      addProductToCatalogue(cat.id, product);
    } catch (_) {}
  }

  void addProductToExistingCatalogue(String name, ProductModel product) {
    addProductToExistingCatalogueByName(name, product);
  }

  // ── REMOVE PRODUCT ──
  void removeProductFromCatalogue(String catalogueId, String productId) {
    final idx = myCatalogues.indexWhere((c) => c.id == catalogueId);
    if (idx == -1) return;
    final cat = myCatalogues[idx];
    cat.products.removeWhere((p) => p.id.toString() == productId);
    myCatalogues[idx] = cat.copyWith(
      products: List<ProductModel>.from(cat.products),
    );
    myCatalogues.refresh();

    _doPush(() async {
      final uid = await _uid();
      if (uid == null) return;
      await ApiService().updateCatalogOnServer(
        userId: uid,
        catalogId: catalogueId,
        action: 'remove_product',
        productId: int.tryParse(productId) ?? 0,
      );
    });
  }

  // =========================================================================
  // PUSH WITH LOCK — Core fix for the race condition
  //
  // 1. Increment _activePushes (blocks polling)
  // 2. Await the server push
  // 3. Wait 500ms (give server time to write)
  // 4. Force fetch from server (confirm state)
  // 5. Decrement _activePushes (resume polling)
  // =========================================================================

  Future<void> _doPush(Future<void> Function() serverAction) async {
    _activePushes++;
    debugPrint(
      'CatalogSync: Push started (active=$_activePushes, polling paused)',
    );

    try {
      await serverAction();
      // Give the server a moment to persist
      await Future.delayed(const Duration(milliseconds: 500));
      // Force fetch to confirm server state
      await _forceFetch();
    } catch (e) {
      debugPrint('CatalogSync: Push error: $e');
      // Still fetch to restore correct state
      await _forceFetch();
    } finally {
      _activePushes--;
      debugPrint('CatalogSync: Push done (active=$_activePushes)');
    }
  }

  // =========================================================================
  // FETCH FROM SERVER — Two variants
  // =========================================================================

  /// Force fetch — ignores _isFetching guard, always runs
  Future<void> _forceFetch() async {
    _isFetching = true;
    isSyncing.value = true;
    try {
      await _doFetch();
    } finally {
      _isFetching = false;
      isSyncing.value = false;
    }
  }

  /// Poll fetch — respects _isFetching guard, skips if busy
  Future<void> _fetchFromServer() async {
    if (_isFetching) return;
    _isFetching = true;
    isSyncing.value = true;
    try {
      await _doFetch();
    } finally {
      _isFetching = false;
      isSyncing.value = false;
    }
  }

  /// Actual fetch logic — shared by both force and poll
  Future<void> _doFetch() async {
    try {
      final userId = await _uid();
      if (userId == null) return;

      final serverCatalogs = await ApiService().fetchCatalogsFromServer(
        userId: userId,
      );
      if (serverCatalogs == null) return; // Network error, keep current

      // Collect all product IDs
      final Set<int> allPids = {};
      for (final cat in serverCatalogs) {
        for (final pid in (cat['products'] as List? ?? [])) {
          final id = (pid is int) ? pid : (int.tryParse(pid.toString()) ?? 0);
          if (id > 0) allPids.add(id);
        }
      }

      // Batch fetch missing products
      final missing = allPids
          .where((id) => !_productCache.containsKey(id))
          .toList();
      if (missing.isNotEmpty) await _batchFetch(missing);

      // Build fresh catalog list
      final List<CatalogueModel> fresh = [];
      for (final cat in serverCatalogs) {
        final String id = cat['id'] ?? '';
        if (id.isEmpty) continue;

        final List<ProductModel> products = [];
        for (final pid in (cat['products'] as List? ?? [])) {
          final int pId = (pid is int)
              ? pid
              : (int.tryParse(pid.toString()) ?? 0);
          if (pId > 0 && _productCache.containsKey(pId)) {
            products.add(_productCache[pId]!);
          }
        }

        fresh.add(
          CatalogueModel(
            id: id,
            name: cat['name'] ?? '',
            description: cat['desc'] ?? '',
            createdAt:
                DateTime.tryParse(cat['created'] ?? '') ?? DateTime.now(),
            products: products,
          ),
        );
      }

      // Replace the entire list — server is truth
      myCatalogues.assignAll(fresh);
      myCatalogues.refresh();
      isLoaded.value = true;
    } catch (e) {
      debugPrint('CatalogSync: fetch error: $e');
    }
  }

  // =========================================================================
  // BATCH PRODUCT FETCH
  // =========================================================================

  Future<void> _batchFetch(List<int> ids) async {
    if (ids.isEmpty) return;

    // Try batch endpoint first
    try {
      final result = await ApiService().batchFetchProducts(productIds: ids);
      if (result != null && result.isNotEmpty) {
        for (final p in result) {
          _productCache[p.id] = p;
        }
        return;
      }
    } catch (_) {}

    // Fallback: individual fetch
    for (final pid in ids) {
      try {
        final p = await ApiService().fetchProductByIdSafe(pid.toString());
        if (p != null) _productCache[pid] = p;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  Future<String?> _uid() async {
    if (_cachedUserId != null) return _cachedUserId;
    final user = await SessionService.getUser();
    if (user == null) return null;
    _cachedUserId = user.wooCustomerId.isNotEmpty
        ? user.wooCustomerId
        : (user.userId.isNotEmpty ? user.userId : null);
    return _cachedUserId;
  }

  String _genId() =>
      'cat_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
}
