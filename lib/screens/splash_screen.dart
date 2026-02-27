// lib/screens/splash_screen.dart
//
// UPDATED: Background refresh now preserves wooCustomerId
// so catalog sync and other features work after app restart.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _graphqlUrl = "https://kiranelectro.com/kakiso/graphql";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Start the services and the timer in parallel
    final initFuture = SessionService.init();
    final minSplashTime = Future.delayed(const Duration(milliseconds: 1500));

    await initFuture;

    // 2. Check for cached session
    final String? authToken = await SessionService.getAuthToken();
    final UserData? cachedUser = await SessionService.getUser();

    // 3. Logic: Logged out? -> Wait for timer, then Intro.
    if (authToken == null || authToken.isEmpty || cachedUser == null) {
      await minSplashTime;
      Get.offAll(() => const KakisoIntroScreen());
      return;
    }

    // 4. Logic: Logged in? -> Fire background refresh, wait for timer, then Home.
    _silentBackgroundRefresh(authToken, cachedUser);

    await minSplashTime;
    Get.offAll(() => NavigationMenu(userData: cachedUser));
  }

  Future<void> _silentBackgroundRefresh(
    String token,
    UserData cachedUser,
  ) async {
    try {
      final freshUser = await _fetchUserData(token, cachedUser);
      await SessionService.saveSession(authToken: token, user: freshUser);
      debugPrint("Background user refresh successful");
    } catch (e) {
      debugPrint("Background refresh failed (ignoring): $e");
    }
  }

  /// Fetch fresh user data from GraphQL, but PRESERVE wooCustomerId
  /// from the cached session (GraphQL doesn't return it).
  Future<UserData> _fetchUserData(String token, UserData cachedUser) async {
    final HttpLink httpLink = HttpLink(_graphqlUrl);
    final AuthLink authLink = AuthLink(getToken: () async => 'Bearer $token');
    final Link link = authLink.concat(httpLink);

    final client = GraphQLClient(link: link, cache: GraphQLCache());

    const String getMeQuery = r'''
      query GetMe {
        viewer {
          databaseId
          email
          firstName
          lastName
          registeredDate
          avatar {
            url
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(getMeQuery),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await client
        .query(options)
        .timeout(const Duration(seconds: 5));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data != null && result.data!['viewer'] != null) {
      final userData = result.data!['viewer'];
      final String wpEmail =
          (userData['email'] as String?)?.trim() ?? cachedUser.email;
      final String firstName = (userData['firstName'] as String?) ?? '';
      final String lastName = (userData['lastName'] as String?) ?? '';
      final String fullName = ('$firstName $lastName').trim().isNotEmpty
          ? ('$firstName $lastName').trim()
          : wpEmail.split('@').first;

      // CRITICAL: Preserve wooCustomerId from cached session
      // GraphQL viewer query doesn't return WooCommerce customer ID
      String wooId = cachedUser.wooCustomerId;

      // If wooCustomerId is missing (old session), try to fetch it
      if (wooId.isEmpty) {
        try {
          final freshWooId = await ApiService().ensureWooCustomer(
            email: wpEmail,
            name: fullName,
          );
          wooId = freshWooId ?? '';
        } catch (_) {}
      }

      return UserData(
        name: fullName,
        email: wpEmail,
        userId: userData['databaseId'].toString(),
        wooCustomerId: wooId,
        joined:
            DateTime.tryParse(userData['registeredDate'] ?? '') ??
            DateTime.now(),
        profilePicUrl: userData['avatar']?['url'] ?? '',
        phone: cachedUser.phone, // Preserve phone too
      );
    } else {
      throw Exception('Failed to get user data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logos/login-logo.png',
          width: 150.0,
          height: 150.0,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
