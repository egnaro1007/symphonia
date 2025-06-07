import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:symphonia/models/friend_request.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/friend.dart';
import 'package:symphonia/services/user_event_manager.dart';
import 'package:symphonia/widgets/user_avatar.dart';
import 'dart:async';

class FriendRequestsScreen extends AbstractScreen {
  @override
  final String title = "Lời mời kết bạn";

  @override
  final Icon icon = const Icon(Icons.person_add);

  const FriendRequestsScreen({super.key, required super.onTabSelected});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  late List<FriendRequest> _friendRequests = [];
  StreamSubscription<UserEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
    _setupEventListener();
  }

  void _setupEventListener() {
    _eventSubscription = UserEventManager().events.listen((event) {
      // Reload friend requests when relevant events occur
      if (event.type == UserEventType.friendRequestSent ||
          event.type == UserEventType.friendRequestAccepted ||
          event.type == UserEventType.friendRequestRejected) {
        _loadFriendRequests();
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFriendRequests() async {
    final requests = await FriendOperations.getFriendRequests();
    setState(() {
      _friendRequests = requests;
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
          AppLocalizations.of(context)!.friendRequests,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Go back to previous screen using navigation stack
            widget.onTabSelected(-1, "");
          },
        ),
      ),
      body:
          _friendRequests.isEmpty
              ? Center(
                child: Text(
                  AppLocalizations.of(context)!.noFriendRequest,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Hiển thị số lượng lời mời
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      '${_friendRequests.length} ${AppLocalizations.of(context)!.friendRequests}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Danh sách lời mời kết bạn
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _friendRequests.length,
                    itemBuilder: (context, index) {
                      final request = _friendRequests[index];
                      return FriendRequestCard(
                        request: request,
                        onAccept: () async {
                          await FriendOperations.responseFriendRequest(
                            _friendRequests[index].id,
                            "accept",
                          );
                          UserEventManager().notifyFriendRequestAccepted(
                            _friendRequests[index].sender_id,
                          );
                          _loadFriendRequests();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${AppLocalizations.of(context)!.acceptFriendRequestFrom} ${request.name}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        onDecline: () async {
                          await FriendOperations.responseFriendRequest(
                            _friendRequests[index].id,
                            "reject",
                          );
                          UserEventManager().notifyFriendRequestRejected(
                            _friendRequests[index].sender_id,
                          );
                          _loadFriendRequests();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${AppLocalizations.of(context)!.declineFriendRequestFrom} ${request.name}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const FriendRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng
            Row(
              children: [
                // Ảnh đại diện
                UserAvatar(
                  radius: 30,
                  avatarUrl: request.profilePictureUrl,
                  userName: request.name,
                ),
                const SizedBox(width: 16),
                // Thông tin cơ bản
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Các nút hành động
            Row(
              children: [
                // Nút chấp nhận
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.accept),
                  ),
                ),
                const SizedBox(width: 12),
                // Nút từ chối
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.decline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
