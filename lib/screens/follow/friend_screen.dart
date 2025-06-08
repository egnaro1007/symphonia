import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/user.dart';
import 'package:symphonia/services/friend.dart';
import 'package:symphonia/widgets/user_avatar.dart';
import '../abstract_navigation_screen.dart';
import 'package:symphonia/services/user_event_manager.dart';
import 'package:symphonia/constants/screen_index.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.user,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút tìm kiếm
          IconButton(
            icon: Icon(Icons.search, color: colorScheme.onSurface),
            onPressed: () {
              widget.onTabSelected(ScreenIndex.searchUser.value, "");
            },
          ),
          // Nút thông báo
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: colorScheme.onSurface),
                onPressed: () {
                  widget.onTabSelected(ScreenIndex.friendRequests.value, "");
                },
              ),
              if (numberOfFriendRequests > 0)
                Positioned(
                  right: 4,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
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
                      style: TextStyle(
                        color: colorScheme.onError,
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
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tiêu đề danh sách bạn bè
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              AppLocalizations.of(context)!.yourFriends,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
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
                color: colorScheme.surface,
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
                      widget.onTabSelected(
                        ScreenIndex.userProfile.value,
                        friend.id,
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '@${friend.username}',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
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
                              backgroundColor: colorScheme.surface,
                              title: Text(
                                AppLocalizations.of(context)!.confirm,
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                              content: Text(
                                "${AppLocalizations.of(context)!.friendRemoveConfirmation} ${friend.fullName}?",
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    // Show loading indicator
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${AppLocalizations.of(context)!.removingFriendWith} ${friend.fullName}...',
                                        ),
                                        backgroundColor: colorScheme.secondary,
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
                                            '${AppLocalizations.of(context)!.confirmRemovingFriendWith} ${friend.fullName}',
                                          ),
                                          backgroundColor: colorScheme.tertiary,
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
                                          backgroundColor: colorScheme.error,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.confirm,
                                    style: TextStyle(color: colorScheme.error),
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
