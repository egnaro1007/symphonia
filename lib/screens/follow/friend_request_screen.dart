import 'package:flutter/material.dart';
import 'package:symphonia/models/friend_request.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';
import 'package:symphonia/services/friend.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
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
        title: const Text(
          'Lời mời kết bạn',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            widget.onTabSelected(2, "");
          },
        ),
      ),
      body: _friendRequests.isEmpty
          ? const Center(
        child: Text(
          'Không có lời mời kết bạn nào',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hiển thị số lượng lời mời
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              '${_friendRequests.length} lời mời kết bạn',
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
                  await FriendOperations.responseFriendRequest(_friendRequests[index].id, "accept");
                  _loadFriendRequests();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chấp nhận lời mời từ ${request.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onDecline: () async {
                  await FriendOperations.responseFriendRequest(_friendRequests[index].id, "reject");
                  _loadFriendRequests();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã từ chối lời mời từ ${request.name}'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng
            Row(
              children: [
                // Ảnh đại diện
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(request.avatarUrl),
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
                    child: const Text('Chấp nhận'),
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
                    child: const Text('Từ chối'),
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