import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakiso_reseller_app/screens/intro/intro.dart';

// --- Imports Added for Login Check ---
import 'package:get/get.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/screens/dashboard/example.dart';
// --- End of Added Imports ---

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // --- Added for Login Check ---
  final String _graphqlUrl = "https://prod-kakiso.smitpatadiya.me/graphql";
  final _storage = const FlutterSecureStorage();
  // --- End of Added ---

  @override
  void initState() {
    super.initState();
    // Replaced the simple 3-second timer with our login check logic
    _checkLoginStatus();
  }

  /// Checks secure storage for a token and validates it.
  Future<void> _checkLoginStatus() async {
    // Wait for 1.5 seconds (to show your logo)
    await Future.delayed(const Duration(milliseconds: 1500));

    final authToken = await _storage.read(key: 'authToken');

    if (authToken == null || authToken.isEmpty) {
      // No token found, go to your KIntroScreen
      Get.offAll(() => const KIntroScreen());
      return;
    }

    // Token found, now we must validate it and fetch the user's data
    try {
      final userData = await _fetchUserData(authToken);
      // Token is valid and we have data, go to Dashboard
      Get.offAll(() => UserDashboardPage(userData: userData));
    } catch (e) {
      // Token is invalid or expired
      print("Token validation failed: $e");
      // Clear the bad token
      await _storage.delete(key: 'authToken');
      // Go to your KIntroScreen
      Get.offAll(() => const KIntroScreen());
    }
  }

  /// Fetches the current user's data using a saved token.
  Future<UserData> _fetchUserData(String token) async {
    // 1. Setup an AuthLink to send the token in the headers
    final HttpLink httpLink = HttpLink(_graphqlUrl);
    final AuthLink authLink = AuthLink(getToken: () async => 'Bearer $token');
    final Link link = authLink.concat(httpLink);

    // 2. Create a new client with this authenticated link
    final client = GraphQLClient(link: link, cache: GraphQLCache());

    // 3. This is the "get me" query
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
    // This is your original UI from your file
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
