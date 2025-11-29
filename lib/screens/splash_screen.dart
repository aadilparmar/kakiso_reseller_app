import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/navigation_menu.dart';
import 'package:kakiso_reseller_app/screens/intro/intro.dart';

import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:kakiso_reseller_app/screens/intro/intro_part2/kakiso_intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";
  final _storage = const FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final authToken = await _storage.read(key: 'authToken');

    if (authToken == null || authToken.isEmpty) {
      Get.offAll(() => const KakisoIntroScreen());
      return;
    }

    try {
      final userData = await _fetchUserData(authToken);
      // Token is valid and we have data, go to Dashboard
      Get.offAll(() => NavigationMenu(userData: userData));
    } catch (e) {
      print("Token validation failed: $e");
      await _storage.delete(key: 'authToken');
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
      // Map the response to your UserData model
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logos/login-logo.png',
              width: 150.0,
              height: 150.0,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
