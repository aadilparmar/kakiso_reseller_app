// lib/screens/splash/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';
import 'package:kakiso_reseller_app/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ✅ FIX 1: Match the URL used in Login (Stage vs Prod mismatch caused the 500 error)
  final String _graphqlUrl = "https://stage.kakiso.com/graphql";

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
    // We do NOT await this. It runs in the background to update storage.
    _silentBackgroundRefresh(authToken);

    // Ensure we show the logo for at least the full duration
    await minSplashTime;

    // Navigate immediately with the cached user (Instant feel)
    Get.offAll(() => NavigationMenu(userData: cachedUser));
  }

  // Moved the network call to a fire-and-forget method or handled inside Home
  // But if you want to keep the validation here, this is the fixed fetcher:
  Future<UserData> _fetchUserData(String token) async {
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
      fetchPolicy: FetchPolicy.networkOnly, // Don't read from cache here
    );

    // Reduced timeout to 5s so we don't hang if we decide to await it
    final QueryResult result = await client
        .query(options)
        .timeout(const Duration(seconds: 5));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    if (result.data != null && result.data!['viewer'] != null) {
      final userData = result.data!['viewer'];
      return UserData(
        name: '${userData['firstName']} ${userData['lastName']}',
        email: userData['email'],
        userId: userData['databaseId'].toString(),
        joined:
            DateTime.tryParse(userData['registeredDate'] ?? '') ??
            DateTime.now(),
        profilePicUrl: userData['avatar']?['url'] ?? '',
      );
    } else {
      throw Exception('Failed to get user data.');
    }
  }

  Future<void> _silentBackgroundRefresh(String token) async {
    try {
      final freshUser = await _fetchUserData(token);
      await SessionService.saveSession(authToken: token, user: freshUser);
      // Note: This saves to storage, but won't update the UI immediately
      // unless you use a State Management solution (like GetxController) for the User.
      debugPrint("Background user refresh successful");
    } catch (e) {
      debugPrint("Background refresh failed (ignoring): $e");
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
