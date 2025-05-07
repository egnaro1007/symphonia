import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/user.dart';
import 'package:symphonia/services/token_manager.dart';

class FriendOperations {
  FriendOperations._();

  static Future<List<User>> getFriends() async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/friend_request'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = response.body;
        var jsonData = jsonDecode(data);

        List<User> friends = [];
        for (var friend in jsonData['friends']) {
          friends.add(User(
            id: friend['id'].toString(),
            username: friend['username'],
          ));
        }

        return friends;

      } else {
        throw Exception('Failed to load friends');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static Future<int> getNumberOfFriendRequests() async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/friend_request'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = response.body;
        var jsonData = jsonDecode(data);

        return jsonData['received_requests'].length;

      } else {
        throw Exception('Failed to load the number of friend requests');
      }
    } catch (e) {
      print('Error: $e');
      return 0;
    }
  }
}