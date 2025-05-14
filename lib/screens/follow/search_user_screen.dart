import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/user.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/token_manager.dart';

class SearchUserScreen extends AbstractScreen {
  @override
  String get title => 'Tìm kiếm người dùng';

  @override
  Icon get icon => const Icon(Icons.search);

  // final String searchQuery;

  const SearchUserScreen({
    super.key,
    // required this.searchQuery,
    required Function(int, String) super.onTabSelected,
  });

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // _searchController.text = widget.searchQuery;

    // If searchQuery is not empty, automatically search when screen initializes
    // if (widget.searchQuery.isNotEmpty) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     _searchUsers(widget.searchQuery);
    //   });
    // }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/auth/search_user/?query=$query'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        List<User> users = [];

        for (var user in data) {
          users.add(User(
            id: user['id'].toString(),
            username: user['username'],
            avatarUrl: "https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg",
          ));
        }

        setState(() {
          _searchResults = users;
          _isLoading = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/auth/friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "id": userId,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lời mời kết bạn'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể gửi lời mời kết bạn'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xảy ra lỗi khi gửi lời mời kết bạn'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm người dùng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên người dùng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onSubmitted: (value) => _searchUsers(value),
            ),

            const SizedBox(height: 16),

            // Search button
            ElevatedButton(
              onPressed: () => _searchUsers(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Tìm kiếm'),
            ),

            const SizedBox(height: 24),

            // Search results
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched && _searchResults.isEmpty
                  ? const Center(child: Text('Không tìm thấy người dùng nào'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onTabSelected(8, user.id);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(user.avatarUrl),
                                  ),
                                  const SizedBox(width: 16),
                                  // Username
                                  Expanded(
                                    child: Text(
                                      user.username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  // Add friend button
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // Prevent the tap from propagating to the card
                                      _sendFriendRequest(user.id);
                                    },
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Kết bạn'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(color: Colors.blue),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}