import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:symphonia/models/user.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/token_manager.dart';
import 'package:symphonia/services/user_event_manager.dart';
import 'package:symphonia/widgets/user_avatar.dart';
import 'package:symphonia/constants/screen_index.dart';

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
  final Set<String> _pendingRequests = {}; // Track pending friend requests

  @override
  void initState() {
    super.initState();
    // Reset search state to ensure clean start
    _resetSearchState();
  }

  void _resetSearchState() {
    _searchController.clear();
    _searchResults.clear();
    _isLoading = false;
    _hasSearched = false;
    _pendingRequests.clear();
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        List<User> users = [];

        for (var user in data) {
          users.add(
            User(
              id: user['id'].toString(),
              username: user['username'],
              avatarUrl:
                  "https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg",
              status: user['relationships_status'] ?? 'none',
              profilePictureUrl: user['profile_picture_url']?.toString(),
              firstName: user['first_name']?.toString(),
              lastName: user['last_name']?.toString(),
              gender: user['gender']?.toString(),
              birthDate: user['birth_date']?.toString(),
              email: user['email']?.toString(),
            ),
          );
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
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String userId) async {
    // Prevent multiple simultaneous requests
    if (_pendingRequests.contains(userId)) {
      return;
    }

    setState(() {
      _pendingRequests.add(userId);
    });

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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.friendRequestSent),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        // Update user status locally
        setState(() {
          for (var user in _searchResults) {
            if (user.id == userId) {
              user.status = 'pending_sent';
              break;
            }
          }
        });
        // Notify other screens
        UserEventManager().notifyFriendRequestSent(userId);
      } else {
        // Try to get error message from response
        String errorMessage =
            'Không thể gửi lời mời kết bạn (Status: ${response.statusCode})';
        try {
          var errorData = jsonDecode(response.body);
          if (errorData.containsKey('error') ||
              errorData.containsKey('message')) {
            errorMessage =
                errorData['error'] ?? errorData['message'] ?? errorMessage;
          }
        } catch (e) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorOccurredFriendRequest,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _pendingRequests.remove(userId);
      });
    }
  }

  Future<void> _unfriend(String userId) async {
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã hủy kết bạn'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        // Update user status locally
        setState(() {
          for (var user in _searchResults) {
            if (user.id == userId) {
              user.status = 'none';
              break;
            }
          }
        });
        // Notify other screens
        UserEventManager().notifyUnfriended(userId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể hủy kết bạn (Status: ${response.statusCode})',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xảy ra lỗi khi hủy kết bạn'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _respondToFriendRequest(String userId, String response) async {
    var serverUrl = dotenv.env['SERVER_URL'];

    try {
      final httpResponse = await http.post(
        Uri.parse('$serverUrl/api/auth/response_friend_request/'),
        headers: {
          'Authorization': 'Bearer ${TokenManager.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"user_id": userId, "response": response}),
      );

      if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 300) {
        String message =
            response == 'accept'
                ? 'Đã chấp nhận lời mời kết bạn'
                : 'Đã từ chối lời mời kết bạn';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
        // Update user status locally
        setState(() {
          for (var user in _searchResults) {
            if (user.id == userId) {
              user.status = response == 'accept' ? 'friend' : 'none';
              break;
            }
          }
        });
        // Notify other screens
        if (response == 'accept') {
          UserEventManager().notifyFriendRequestAccepted(userId);
        } else {
          UserEventManager().notifyFriendRequestRejected(userId);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể phản hồi lời mời kết bạn (Status: ${httpResponse.statusCode})',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xảy ra lỗi khi phản hồi lời mời kết bạn'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.searchUser),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () {
            // Reset search state before going back
            _resetSearchState();
            // Go back to previous screen using navigation stack
            widget.onTabSelected(-1, "");
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterUsername,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: colorScheme.onSurfaceVariant),
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
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
              onSubmitted: (value) => _searchUsers(value),
            ),

            const SizedBox(height: 16),

            // Search button
            ElevatedButton(
              onPressed: () => _searchUsers(_searchController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.search),
            ),

            const SizedBox(height: 24),

            // Search results
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasSearched && _searchResults.isEmpty
                      ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.noUsersFound,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return GestureDetector(
                            onTap: () {
                              widget.onTabSelected(
                                ScreenIndex.userProfile.value,
                                user.id,
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 0,
                              color: colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildUserCard(user),
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

  Widget _buildUserCard(User user) {
    final colorScheme = Theme.of(context).colorScheme;

    if (user.status == 'pending_received') {
      // For pending_received, use vertical layout like friend requests screen
      return Column(
        children: [
          // Top row: Avatar and username
          Row(
            children: [
              UserAvatar(
                radius: 30,
                avatarUrl: user.profilePictureUrl,
                userName: user.username,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom row: Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _respondToFriendRequest(user.id, 'accept');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Chấp nhận'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _respondToFriendRequest(user.id, 'reject');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline),
                    backgroundColor: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Từ chối'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // For other statuses, use horizontal layout
      return Row(
        children: [
          // Avatar
          UserAvatar(
            radius: 30,
            avatarUrl: user.profilePictureUrl,
            userName: user.username,
          ),
          const SizedBox(width: 16),
          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Action button
          _buildActionButton(user),
        ],
      );
    }
  }

  Widget _buildActionButton(User user) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isPending = _pendingRequests.contains(user.id);

    if (user.status == 'none') {
      return OutlinedButton.icon(
        onPressed:
            isPending
                ? null
                : () {
                  _sendFriendRequest(user.id);
                },
        icon:
            isPending
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.person_add),
        label: Text(isPending ? 'Đang gửi...' : 'Kết bạn'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else if (user.status == 'pending_sent') {
      return OutlinedButton.icon(
        onPressed: null, // Disable button for pending_sent
        icon: const Icon(Icons.access_time),
        label: const Text('Đã gửi yêu cầu'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          side: BorderSide(color: colorScheme.onSurfaceVariant),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else if (user.status == 'friend') {
      return OutlinedButton.icon(
        onPressed: () {
          _unfriend(user.id);
        },
        icon: const Icon(Icons.person_remove),
        label: const Text('Hủy kết bạn'),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      // pending_received status - handled in _buildUserCard
      return const SizedBox.shrink();
    }
  }
}
