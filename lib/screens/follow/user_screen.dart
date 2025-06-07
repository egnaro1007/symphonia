import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/user.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/friend.dart';
import 'package:symphonia/services/playlist.dart';
import 'package:symphonia/services/user_event_manager.dart';
import 'package:symphonia/widgets/playlist_item.dart';
import 'package:symphonia/constants/screen_index.dart';
import 'dart:async';

class UserScreen extends AbstractScreen {
  @override
  final String title = "Artist";

  @override
  final Icon icon = const Icon(Icons.person);

  final String userID;
  final String searchQuery;

  UserScreen({
    super.key,
    required this.userID,
    required this.searchQuery,
    required super.onTabSelected,
  });

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late UserStatus userStatus = UserStatus(
    id: '',
    username: 'Unknown User',
    avatarUrl: '',
    status: 'none',
    firstName: '',
    lastName: '',
    gender: '',
    birthDate: '',
    email: '',
  );
  late List<PlayList> playlists = [];
  bool isLoadingUser = true;
  bool isLoadingPlaylists = true;
  StreamSubscription<UserEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocalPlaylists();
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventSubscription = UserEventManager().events.listen((event) {
      // Only react to events related to this user
      if (event.userId == widget.userID) {
        _loadUserData(); // Reload user data when status changes
      }
    });
  }

  @override
  void didUpdateWidget(UserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data when userID changes
    if (oldWidget.userID != widget.userID) {
      setState(() {
        isLoadingUser = true;
        isLoadingPlaylists = true;
        // Reset user status to default while loading
        userStatus = UserStatus(
          id: '',
          username: 'Loading...',
          avatarUrl: '',
          status: 'none',
          firstName: '',
          lastName: '',
          gender: '',
          birthDate: '',
          email: '',
        );
        playlists = [];
      });
      _loadUserData();
      _loadLocalPlaylists();
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final result = await FriendOperations.getUser(widget.userID);
      setState(() {
        userStatus = result;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _loadLocalPlaylists() async {
    try {
      final result = await PlayListOperations.getUserPlaylists(widget.userID);
      setState(() {
        playlists = result;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlists: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoadingPlaylists = false;
      });
    }
  }

  String? _processProfilePictureUrl(String? url) {
    if (url == null || url.isEmpty || url == 'null') return null;

    // If URL already starts with http, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Add server URL prefix if it's a relative path
    String serverUrl = dotenv.env['SERVER_URL'] ?? '';
    if (serverUrl.isNotEmpty && url.startsWith('/')) {
      // Ensure server URL doesn't end with slash
      if (serverUrl.endsWith('/')) {
        serverUrl = serverUrl.substring(0, serverUrl.length - 1);
      }
      return '$serverUrl$url';
    }

    return url;
  }

  String _formatGender(String? gender) {
    switch (gender) {
      case 'M':
        return 'Nam';
      case 'F':
        return 'Nữ';
      case 'O':
        return 'Khác';
      default:
        return 'Không xác định';
    }
  }

  String _formatBirthDate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 'Không có thông tin';
    try {
      final date = DateTime.parse(birthDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return birthDate; // Return as is if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoading = isLoadingUser || isLoadingPlaylists;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Process the profile picture URL to handle relative paths
    String? backgroundImageUrl = _processProfilePictureUrl(
      userStatus.profilePictureUrl,
    );

    // Debug prints to help troubleshoot
    print('Raw profilePictureUrl: ${userStatus.profilePictureUrl}');
    print('Processed backgroundImageUrl: $backgroundImageUrl');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    leading: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        // Go back to previous screen using navigation stack
                        widget.onTabSelected(-1, "");
                      },
                    ),
                    expandedHeight: 350,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(
                              backgroundImageUrl?.isNotEmpty == true
                                  ? backgroundImageUrl!
                                  : "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Add a semi-transparent overlay to ensure text readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.2),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userStatus.fullName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '@${userStatus.username}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              try {
                                                if (userStatus.status ==
                                                    'none') {
                                                  await FriendOperations.sendFriendRequest(
                                                    userStatus.id,
                                                  );
                                                  setState(() {
                                                    userStatus = UserStatus(
                                                      id: userStatus.id,
                                                      username:
                                                          userStatus.username,
                                                      avatarUrl:
                                                          userStatus.avatarUrl,
                                                      status: 'pending_sent',
                                                      profilePictureUrl:
                                                          userStatus
                                                              .profilePictureUrl,
                                                      firstName:
                                                          userStatus.firstName,
                                                      lastName:
                                                          userStatus.lastName,
                                                      gender: userStatus.gender,
                                                      birthDate:
                                                          userStatus.birthDate,
                                                      email: userStatus.email,
                                                    );
                                                  });
                                                  UserEventManager()
                                                      .notifyFriendRequestSent(
                                                        userStatus.id,
                                                      );
                                                } else if (userStatus.status ==
                                                    'pending_received') {
                                                  showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          'Friend Request',
                                                        ),
                                                        content: Text(
                                                          'Do you want to accept friend request from ${userStatus.username}?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              await FriendOperations.responseFriendRequestByUserID(
                                                                userStatus.id,
                                                                "reject",
                                                              );
                                                              setState(() {
                                                                userStatus = UserStatus(
                                                                  id:
                                                                      userStatus
                                                                          .id,
                                                                  username:
                                                                      userStatus
                                                                          .username,
                                                                  avatarUrl:
                                                                      userStatus
                                                                          .avatarUrl,
                                                                  status:
                                                                      'none',
                                                                  profilePictureUrl:
                                                                      userStatus
                                                                          .profilePictureUrl,
                                                                  firstName:
                                                                      userStatus
                                                                          .firstName,
                                                                  lastName:
                                                                      userStatus
                                                                          .lastName,
                                                                  gender:
                                                                      userStatus
                                                                          .gender,
                                                                  birthDate:
                                                                      userStatus
                                                                          .birthDate,
                                                                  email:
                                                                      userStatus
                                                                          .email,
                                                                );
                                                              });
                                                              UserEventManager()
                                                                  .notifyFriendRequestRejected(
                                                                    userStatus
                                                                        .id,
                                                                  );
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Friend request rejected',
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Reject',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                              await FriendOperations.responseFriendRequestByUserID(
                                                                userStatus.id,
                                                                "accept",
                                                              );
                                                              setState(() {
                                                                userStatus = UserStatus(
                                                                  id:
                                                                      userStatus
                                                                          .id,
                                                                  username:
                                                                      userStatus
                                                                          .username,
                                                                  avatarUrl:
                                                                      userStatus
                                                                          .avatarUrl,
                                                                  status:
                                                                      'friend',
                                                                  profilePictureUrl:
                                                                      userStatus
                                                                          .profilePictureUrl,
                                                                  firstName:
                                                                      userStatus
                                                                          .firstName,
                                                                  lastName:
                                                                      userStatus
                                                                          .lastName,
                                                                  gender:
                                                                      userStatus
                                                                          .gender,
                                                                  birthDate:
                                                                      userStatus
                                                                          .birthDate,
                                                                  email:
                                                                      userStatus
                                                                          .email,
                                                                );
                                                              });
                                                              UserEventManager()
                                                                  .notifyFriendRequestAccepted(
                                                                    userStatus
                                                                        .id,
                                                                  );
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Friend request accepted',
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: const Text(
                                                              'Accept',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                } else if (userStatus.status ==
                                                    'friend') {
                                                  // Show confirmation dialog for unfriending
                                                  showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          'Xác nhận',
                                                        ),
                                                        content: Text(
                                                          'Bạn có chắc chắn muốn hủy kết bạn với ${userStatus.fullName}?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: const Text(
                                                              'Hủy',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.pop(
                                                                context,
                                                              );

                                                              // Show loading message
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Đang hủy kết bạn với ${userStatus.fullName}...',
                                                                  ),
                                                                ),
                                                              );

                                                              try {
                                                                await FriendOperations.unfriend(
                                                                  userStatus.id,
                                                                );
                                                                setState(() {
                                                                  userStatus = UserStatus(
                                                                    id:
                                                                        userStatus
                                                                            .id,
                                                                    username:
                                                                        userStatus
                                                                            .username,
                                                                    avatarUrl:
                                                                        userStatus
                                                                            .avatarUrl,
                                                                    status:
                                                                        'none',
                                                                    profilePictureUrl:
                                                                        userStatus
                                                                            .profilePictureUrl,
                                                                    firstName:
                                                                        userStatus
                                                                            .firstName,
                                                                    lastName:
                                                                        userStatus
                                                                            .lastName,
                                                                    gender:
                                                                        userStatus
                                                                            .gender,
                                                                    birthDate:
                                                                        userStatus
                                                                            .birthDate,
                                                                    email:
                                                                        userStatus
                                                                            .email,
                                                                  );
                                                                });
                                                                UserEventManager()
                                                                    .notifyUnfriended(
                                                                      userStatus
                                                                          .id,
                                                                    );

                                                                // Show success message
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Đã hủy kết bạn với ${userStatus.fullName}',
                                                                    ),
                                                                  ),
                                                                );
                                                              } catch (e) {
                                                                ScaffoldMessenger.of(
                                                                  context,
                                                                ).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                      'Lỗi khi hủy kết bạn: ${e.toString()}',
                                                                    ),
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                            child: const Text(
                                                              'Xác nhận',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Lỗi: ${e.toString()}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  userStatus.status == 'none'
                                                      ? Colors.transparent
                                                      : userStatus.status ==
                                                          'pending_sent'
                                                      ? Colors.grey.withOpacity(
                                                        0.3,
                                                      )
                                                      : userStatus.status ==
                                                          'pending_received'
                                                      ? Colors.green
                                                          .withOpacity(0.3)
                                                      : Colors.red.withOpacity(
                                                        0.3,
                                                      ),
                                              side: BorderSide(
                                                color:
                                                    userStatus.status == 'none'
                                                        ? Colors.white
                                                        : userStatus.status ==
                                                            'pending_sent'
                                                        ? Colors.grey
                                                        : userStatus.status ==
                                                            'pending_received'
                                                        ? Colors.green
                                                        : Colors.red,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                if (userStatus.status ==
                                                    'pending_sent')
                                                  const Icon(
                                                    Icons.access_time,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                if (userStatus.status ==
                                                    'pending_received')
                                                  const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                if (userStatus.status ==
                                                    'friend')
                                                  const Icon(
                                                    Icons.person_remove,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                if (userStatus.status == 'none')
                                                  const Icon(
                                                    Icons.person_add,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  userStatus.status == 'none'
                                                      ? 'KẾT BẠN'
                                                      : userStatus.status ==
                                                          'pending_sent'
                                                      ? 'ĐÃ GỬI YÊU CẦU'
                                                      : userStatus.status ==
                                                          'pending_received'
                                                      ? 'CHẤP NHẬN'
                                                      : 'HỦY KẾT BẠN',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // User Information Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cá nhân',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Giới tính: ${_formatGender(userStatus.gender)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.cake_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ngày sinh: ${_formatBirthDate(userStatus.birthDate)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (userStatus.email != null &&
                              userStatus.email!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Email: ${userStatus.email}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Playlist Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildPlaylistSections(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistSections() {
    // Separate playlists by permission type
    List<PlayList> friendsPlaylists =
        playlists
            .where((playlist) => playlist.sharePermission == 'friends')
            .toList();
    List<PlayList> publicPlaylists =
        playlists
            .where((playlist) => playlist.sharePermission == 'public')
            .toList();

    // Check if user is friend to determine if we should show friends playlists
    bool isFriend = userStatus.status == 'friend';
    bool hasVisiblePlaylists =
        publicPlaylists.isNotEmpty || (isFriend && friendsPlaylists.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with total count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Playlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (hasVisiblePlaylists)
              Text(
                '${(isFriend ? friendsPlaylists.length : 0) + publicPlaylists.length} playlist',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Show message if no playlists are visible
        if (!hasVisiblePlaylists)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'Không có playlist công khai',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else ...[
          // Friends Playlists Section (only if user is friend and has friends playlists)
          if (isFriend && friendsPlaylists.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.people, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'Playlist dành cho bạn bè (${friendsPlaylists.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children:
                    friendsPlaylists.map((playlist) {
                      return PlaylistItem(
                        playlist: playlist,
                        isHorizontal: false,
                        showTrailingControls: false,
                        onTap: () {
                          widget.onTabSelected(
                            ScreenIndex.playlist.value,
                            playlist.id,
                          );
                        },
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Public Playlists Section
          if (publicPlaylists.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.public, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Playlist công khai (${publicPlaylists.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children:
                    publicPlaylists.map((playlist) {
                      return PlaylistItem(
                        playlist: playlist,
                        isHorizontal: false,
                        showTrailingControls: false,
                        onTap: () {
                          widget.onTabSelected(
                            ScreenIndex.playlist.value,
                            playlist.id,
                          );
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
