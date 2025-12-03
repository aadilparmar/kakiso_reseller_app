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
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Small delay to show splash logo
    await Future.delayed(const Duration(milliseconds: 1500));

    // Make sure SessionService is ready (safe even if no-op)
    await SessionService.init();

    // Read token + cached user from secure storage
    final String? authToken = await SessionService.getAuthToken();
    final UserData? cachedUser = await SessionService.getUser();

    // ❌ No token OR no cached user => treat as logged out
    if (authToken == null || authToken.isEmpty || cachedUser == null) {
      Get.offAll(() => const KakisoIntroScreen());
      return;
    }

    // ✅ We have a token & cached user → user is "logged in".
    // Now we **optionally** validate the token, but we will NOT log them out
    // if anything fails (timeout, network, invalid token, etc.).
    try {
      final UserData freshUser = await _fetchUserData(
        authToken,
      ).timeout(const Duration(seconds: 10));

      // Refresh stored session (overwrites stale user data)
      await SessionService.saveSession(authToken: authToken, user: freshUser);

      // Go to home with fresh user
      Get.offAll(() => NavigationMenu(userData: freshUser));
    } on TimeoutException catch (e) {
      // ⏱ Slow or no network: just go in with cached user
      debugPrint("Splash token validation timeout: $e");
      Get.offAll(() => NavigationMenu(userData: cachedUser));
    } catch (e) {
      // Any other error (network, auth, server, etc.)
      debugPrint("Splash token validation error: $e");

      // 🔴 IMPORTANT:
      // We DO NOT clear SessionService and DO NOT send to intro.
      // We still treat the user as logged in using cached data.
      Get.offAll(() => NavigationMenu(userData: cachedUser));
    }
  }

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

    final QueryOptions options = QueryOptions(document: gql(getMeQuery));
    final QueryResult result = await client.query(options);

    if (result.hasException) {
      // Same kind of OperationException you saw in logs
      throw Exception(result.exception.toString());
    }

    if (result.data != null && result.data!['viewer'] != null) {
      final userData = result.data!['viewer'];

      return UserData(
        name: '${userData['firstName']} ${userData['lastName']}',
        email: userData['email'],
        userId: userData['databaseId'].toString(),
        joined: DateTime.parse(userData['registeredDate']),
        profilePicUrl: userData['avatar']?['url'] ?? '',
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
