import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/friend_request.dart';
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
          friends.add(
            User(
              id: friend['id'].toString(),
              username: friend['username'],
              avatarUrl:
                  "https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg", // friend['avatar_url'],
              status: 'friend', // Friends have 'friend' status
              profilePictureUrl: friend['profile_picture_url']?.toString(),
              firstName: friend['first_name']?.toString(),
              lastName: friend['last_name']?.toString(),
              gender: friend['gender']?.toString(),
              birthDate: friend['birth_date']?.toString(),
              email: friend['email']?.toString(),
            ),
          );
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

  static Future<List<FriendRequest>> getFriendRequests() async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = response.body;
        var jsonData = jsonDecode(data);

        List<FriendRequest> friendRequests = [];
        for (var request in jsonData['received_requests']) {
          friendRequests.add(
            FriendRequest(
              id: request['id'].toString(),
              sender_id: request['sender_user_id'].toString(),
              name: request['sender_username'],
              avatarUrl:
                  "https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg", // request['avatar_url'],
              profilePictureUrl: request['profile_picture_url']?.toString(),
              firstName: request['first_name']?.toString(),
              lastName: request['last_name']?.toString(),
              gender: request['gender']?.toString(),
              birthDate: request['birth_date']?.toString(),
              email: request['email']?.toString(),
            ),
          );
        }

        return friendRequests;
      } else {
        throw Exception('Failed to load friend requests');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static Future<bool> responseFriendRequest(String id, String resp) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/response_friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"id": id, "response": resp}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to respond to friend request');
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  static Future<UserStatus> getUser(String id) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/get_user_info/$id/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = response.body;
        var jsonData = jsonDecode(data);

        return UserStatus(
          id: jsonData['id'].toString(),
          username: jsonData['username'],
          avatarUrl:
              "https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg",
          status: jsonData['relationships_status'],
          profilePictureUrl: jsonData['profile_picture_url']?.toString(),
          firstName: jsonData['first_name']?.toString(),
          lastName: jsonData['last_name']?.toString(),
          gender: jsonData['gender']?.toString(),
          birthDate: jsonData['birth_date']?.toString(),
          email: jsonData['email']?.toString(),
        );
      } else {
        throw Exception('Failed to load user');
      }
    } catch (e) {
      print('Error: $e');
      return UserStatus(
        id: '',
        username: '',
        avatarUrl: '',
        status: '',
        firstName: '',
        lastName: '',
        gender: '',
        birthDate: '',
        email: '',
      );
    }
  }

  static Future<void> sendFriendRequest(String userId) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"id": userId}),
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to send friend request');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<bool> responseFriendRequestByUserID(
    String userID,
    String resp,
  ) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/response_friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"user_id": userID, "response": resp}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to respond to friend request');
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  static Future<void> unfriend(String userId) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/unfriend/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"id": userId}),
      );

      if (response.statusCode == 200) {
      } else {
        throw Exception('Failed to unfriend');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
