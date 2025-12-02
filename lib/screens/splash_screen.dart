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

    // Ensure SessionService is initialized (safe to call multiple times)
    await SessionService.init();

    // 🔹 Read token from secure storage via SessionService
    final authToken = await SessionService.getAuthToken();

    // ❌ No token => user is logged out -> go to intro
    if (authToken == null || authToken.isEmpty) {
      Get.offAll(() => const KakisoIntroScreen());
      return;
    }

    // ✅ Token exists: verify by calling /viewer
    try {
      final userData = await _fetchUserData(authToken);

      // You may also want to re-save it to overwrite any stale user in storage:
      await SessionService.saveSession(authToken: authToken, user: userData);

      // Token valid & user fetched -> go to home/dashboard
      Get.offAll(() => NavigationMenu(userData: userData));
    } catch (e) {
      // Token failed (expired/invalid) -> clear and go to intro
      debugPrint("Token validation failed: $e");
      await SessionService.clearSession();
      Get.offAll(() => const KakisoIntroScreen());
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
