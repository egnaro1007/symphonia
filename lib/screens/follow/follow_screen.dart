import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/user.dart';
import 'package:symphonia/services/friend.dart';
import 'package:symphonia/widgets/user_avatar.dart';
import '../abstract_navigation_screen.dart';
import 'package:symphonia/services/user_event_manager.dart';
import 'dart:async';

class FollowScreen extends AbstractScreen {
  @override
  final String title = "Friends";

  @override
  final Icon icon = const Icon(Icons.subscriptions);

  const FollowScreen({super.key, required super.onTabSelected});

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  List<User> friends = [];
  int numberOfFriendRequests = 0;
  StreamSubscription<UserEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadNumberOfFriendRequests();
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventSubscription = UserEventManager().events.listen((event) {
      // Reload friends list and friend requests when any friendship-related event occurs
      if (event.type == UserEventType.friendRequestAccepted ||
          event.type == UserEventType.unfriended) {
        _loadFriends();
      }
      if (event.type == UserEventType.friendRequestSent ||
          event.type == UserEventType.friendRequestAccepted ||
          event.type == UserEventType.friendRequestRejected) {
        _loadNumberOfFriendRequests();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    final loadedFriends = await FriendOperations.getFriends();
    setState(() {
      friends = loadedFriends;
    });
  }

  Future<void> _loadNumberOfFriendRequests() async {
    final loadedNumberOfFriendRequests =
        await FriendOperations.getNumberOfFriendRequests();
    setState(() {
      numberOfFriendRequests = loadedNumberOfFriendRequests;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.user,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút tìm kiếm
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              widget.onTabSelected(10, "");
            },
          ),
          // Nút thông báo
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {
                  widget.onTabSelected(9, "");
                },
              ),
              if (numberOfFriendRequests > 0)
                Positioned(
                  right: 4,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      numberOfFriendRequests > 99
                          ? '99+'
                          : numberOfFriendRequests.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          // Tiêu đề danh sách bạn bè
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.yourFriends,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Danh sách bạn bè
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: UserAvatar(
                    radius: 24,
                    avatarUrl: friend.profilePictureUrl,
                    userName: friend.username,
                  ),
                  title: GestureDetector(
                    onTap: () {
                      widget.onTabSelected(8, friend.id);
                    },
                    child: Text(
                      friend.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.removeFriend),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(
                                AppLocalizations.of(context)!.confirm,
                              ),
                              content: Text(
                                "${AppLocalizations.of(context)!.friendRemoveConfirmation} ${friend.username}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context)!.removingFriendWith} ${friend.username}...',
                                        ),
                                      ),
                                    );

                                    try {
                                      await FriendOperations.unfriend(
                                        friend.id,
                                      );
                                      // Refresh friends list
                                      await _loadFriends();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${AppLocalizations.of(context)!.confirmRemovingFriendWith} ${friend.username}',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${AppLocalizations.of(context)!.errorRemoveFriend}: ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.confirm,
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
