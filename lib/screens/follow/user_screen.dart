import 'package:flutter/material.dart';
import 'package:symphonia/models/playlist.dart';
import 'package:symphonia/models/user.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/friend.dart';
import 'package:symphonia/services/playlist.dart';

class UserScreen extends AbstractScreen {
  @override
  final String title = "Artist";

  @override
  final Icon icon = const Icon(Icons.person);

  String userID;
  String searchQuery;

  UserScreen({super.key, required this.userID, required this.searchQuery, required super.onTabSelected});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  late UserStatus userStatus = UserStatus(
    id: '',
    username: 'Unknown User',
    avatarUrl: '',
    status: 'none',
  );
  late List<PlayList> playlists = [];
  bool isLoadingUser = true;
  bool isLoadingPlaylists = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLocalPlaylists();
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
      final result = await PlayListOperations.getLocalPlaylists();
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

  @override
  Widget build(BuildContext context) {
    bool isLoading = isLoadingUser || isLoadingPlaylists;

    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    print("Playlist: ${playlists}");

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
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      onPressed: () {
                        print("Search query: ${widget.searchQuery}");
                        widget.onTabSelected(10, widget.searchQuery);
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.more_vert, color: Colors.white),
                        ),
                        onPressed: () {},
                      ),
                    ],
                    expandedHeight: 240,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage("https://sites.dartmouth.edu/dems/files/2021/01/facebook-avatar-copy-4.jpg"),
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
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userStatus.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () async {
                                              print("User status: ${userStatus.status}");

                                              try {
                                                if (userStatus.status == 'none') {
                                                  await FriendOperations.sendFriendRequest(userStatus.id);
                                                  setState(() {
                                                    userStatus = UserStatus(
                                                      id: userStatus.id,
                                                      username: userStatus.username,
                                                      avatarUrl: userStatus.avatarUrl,
                                                      status: 'pending_sent',
                                                    );
                                                  });
                                                } else if (userStatus.status == 'pending_received') {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return AlertDialog(
                                                        title: const Text('Friend Request'),
                                                        content: Text('Do you want to accept friend request from ${userStatus.username}?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.of(context).pop();
                                                              await FriendOperations.responseFriendRequestByUserID(userStatus.id, "reject");
                                                              setState(() {
                                                                userStatus = UserStatus(
                                                                  id: userStatus.id,
                                                                  username: userStatus.username,
                                                                  avatarUrl: userStatus.avatarUrl,
                                                                  status: 'none',
                                                                );
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Friend request rejected')),
                                                              );
                                                            },
                                                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              Navigator.of(context).pop();
                                                              await FriendOperations.responseFriendRequestByUserID(userStatus.id, "accept");
                                                              setState(() {
                                                                userStatus = UserStatus(
                                                                  id: userStatus.id,
                                                                  username: userStatus.username,
                                                                  avatarUrl: userStatus.avatarUrl,
                                                                  status: 'friend',
                                                                );
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(content: Text('Friend request accepted')),
                                                              );
                                                            },
                                                            child: const Text('Accept', style: TextStyle(color: Colors.green)),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                } else if (userStatus.status == 'friend') {
                                                  await FriendOperations.unfriend(userStatus.id);
                                                  setState(() {
                                                    userStatus = UserStatus(
                                                      id: userStatus.id,
                                                      username: userStatus.username,
                                                      avatarUrl: userStatus.avatarUrl,
                                                      status: 'none',
                                                    );
                                                  });
                                                }
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                                                );
                                              }
                                            },
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor: userStatus.status == 'none' ? Colors.transparent :
                                                              userStatus.status == 'pending_sent' ? Colors.grey.withOpacity(0.3) :
                                                              userStatus.status == 'pending_received' ? Colors.green.withOpacity(0.3) :
                                                              Colors.red.withOpacity(0.3),
                                              side: BorderSide(
                                                color: userStatus.status == 'none' ? Colors.white :
                                                      userStatus.status == 'pending_sent' ? Colors.grey :
                                                      userStatus.status == 'pending_received' ? Colors.green :
                                                      Colors.red,
                                                width: 1.5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (userStatus.status == 'pending_sent')
                                                  const Icon(Icons.access_time, color: Colors.white, size: 16),
                                                if (userStatus.status == 'pending_received')
                                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                                                if (userStatus.status == 'friend')
                                                  const Icon(Icons.person_remove, color: Colors.white, size: 16),
                                                if (userStatus.status == 'none')
                                                  const Icon(Icons.person_add, color: Colors.white, size: 16),
                                                const SizedBox(width: 8),
                                                Text(
                                                  userStatus.status == 'none' ? 'KẾT BẠN' :
                                                  userStatus.status == 'pending_sent' ? 'ĐÃ GỬI YÊU CẦU' :
                                                  userStatus.status == 'pending_received' ? 'CHẤP NHẬN' :
                                                  'HỦY KẾT BẠN',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF8257E5),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(30),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text(
                                              'PHÁT NHẠC',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
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

                  // Song List
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         const Text(
                  //           'Bài Hát Nổi Bật',
                  //           style: TextStyle(
                  //             fontSize: 20,
                  //             fontWeight: FontWeight.bold,
                  //           ),
                  //         ),
                  //         Icon(
                  //           Icons.chevron_right,
                  //           color: Colors.grey[700],
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  //
                  // SliverList(
                  //   delegate: SliverChildListDelegate([
                  //     _buildSongItem(
                  //       'Bắc Bling (Bắc Ninh)',
                  //       'Hòa Minzy, Xuân Hinh, Tuấn Cry, Masew',
                  //       'assets/images/song1.jpg',
                  //     ),
                  //     _buildSongItem(
                  //       'Bật Tình Yêu Lên',
                  //       'Tăng Duy Tân, Hòa Minzy',
                  //       'assets/images/song2.jpg',
                  //     ),
                  //     _buildSongItem(
                  //       'Rời Bỏ',
                  //       'Hòa Minzy',
                  //       'assets/images/song3.jpg',
                  //     ),
                  //     _buildSongItem(
                  //       'Kén Cá Chọn Canh',
                  //       'Hòa Minzy',
                  //       'assets/images/song4.jpg',
                  //     ),
                  //   ]),
                  // ),

                  // Playlist Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Playlist',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                            if (playlists.isEmpty)
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'Không có playlist',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...playlists.take(2).map((playlist) =>
                                Expanded(
                                     child: GestureDetector(
                                       onTap: () {
                                         widget.onTabSelected(6, playlist.id);
                                       },
                                       child: Padding(
                                         padding: EdgeInsets.only(right: playlists.indexOf(playlist) < playlists.length - 1 ? 8.0 : 0),
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             AspectRatio(
                                               aspectRatio: 1,
                                               child: Container(
                                                 decoration: BoxDecoration(
                                                   borderRadius: BorderRadius.circular(8),
                                                   image: DecorationImage(
                                                     image: NetworkImage(playlist.picture),
                                                     fit: BoxFit.cover,
                                                   ),
                                                 ),
                                               ),
                                             ),
                                             const SizedBox(height: 8),
                                             Text(
                                               playlist.title,
                                               maxLines: 2,
                                               overflow: TextOverflow.ellipsis,
                                               style: const TextStyle(
                                                 fontWeight: FontWeight.w500,
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                   )
                              ).toList(),
                            ],
                          ),
                        ],
                      ),
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

  // Widget _buildSongItem(String title, String artists, String imagePath) {
  //   return ListTile(
  //     contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     leading: ClipRRect(
  //       borderRadius: BorderRadius.circular(8),
  //       child: Container(
  //         width: 56,
  //         height: 56,
  //         color: Colors.grey[300],
  //         // In a real app, you'd use Image.asset(imagePath) instead
  //         child: const Icon(Icons.music_note, color: Colors.grey),
  //       ),
  //     ),
  //     title: Text(
  //       title,
  //       style: const TextStyle(
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //     subtitle: Text(
  //       artists,
  //       style: TextStyle(
  //         color: Colors.grey[600],
  //         fontSize: 13,
  //       ),
  //     ),
  //     trailing: const Icon(Icons.more_vert),
  //   );
  // }

  Widget _buildPlaylistItem(PlayList playlist) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(playlist.picture),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          playlist.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}