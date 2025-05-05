import 'package:flutter/material.dart';
import 'package:symphonia/models/user.dart';
import '../abstract_navigation_screen.dart';

class FollowScreen extends AbstractScreen {
  @override
  final String title = "Follow";

  @override
  final Icon icon = const Icon(Icons.subscriptions);

  FollowScreen({required super.onTabSelected});

  @override
  State<FollowScreen> createState() => _FollowScreenState();
}

class _FollowScreenState extends State<FollowScreen> {
  // Danh sách bạn bè mẫu
  final List<User> _friends = [
    User(id: '1', username: 'Nguyễn Văn A'),
    User(id: '2', username: 'Trần Thị B'),
    User(id: '3', username: 'Lê Văn C'),
    User(id: '4', username: 'Phạm Thị D'),
    User(id: '5', username: 'Nguyễn Văn E'),
    User(id: '6', username: 'Trần Thị F'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Người dùng',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút tìm kiếm
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tìm kiếm được nhấn')),
              );
            },
          ),
          // Nút thông báo
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thông báo được nhấn')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tiêu đề danh sách bạn bè
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Bạn bè của bạn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Danh sách bạn bè
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _friends.length,
            itemBuilder: (context, index) {
              final friend = _friends[index];
              return FriendListItem(friend: friend);
            },
          ),
        ],
      ),
    );
  }
}

class FriendListItem extends StatelessWidget {
  final User friend;

  const FriendListItem({
    Key? key,
    required this.friend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: Text('👤', style: TextStyle(fontSize: 24)),
            ),
          ],
        ),
        title: Text(
          friend.username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
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
          child: const Text("Hủy kết bạn"),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Xác nhận"),
                content: Text("Bạn có chắc muốn hủy kết bạn với ${friend.username}?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Hủy"),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã hủy kết bạn với ${friend.username}')),
                      );
                    },
                    child: const Text("Xác nhận"),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}