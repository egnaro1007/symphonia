import 'package:flutter/material.dart';
import 'package:symphonia/screens/abstract_navigation_screen.dart';

class FriendRequestsScreen extends AbstractScreen {
  @override
  final String title = "Lời mời kết bạn";

  @override
  final Icon icon = const Icon(Icons.person_add);

  FriendRequestsScreen({required super.onTabSelected});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  // Danh sách lời mời kết bạn mẫu
  final List<FriendRequest> _friendRequests = [
    FriendRequest(
      id: '1',
      name: 'Nguyễn Văn A',
      avatarUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
      mutualFriends: 5,
      timeAgo: '2 giờ trước',
    ),
    FriendRequest(
      id: '2',
      name: 'Trần Thị B',
      avatarUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
      mutualFriends: 2,
      timeAgo: '5 giờ trước',
    ),
    FriendRequest(
      id: '3',
      name: 'Lê Văn C',
      avatarUrl: 'https://randomuser.me/api/portraits/men/13.jpg',
      mutualFriends: 8,
      timeAgo: '1 ngày trước',
    ),
    FriendRequest(
      id: '4',
      name: 'Phạm Thị D',
      avatarUrl: 'https://randomuser.me/api/portraits/women/14.jpg',
      mutualFriends: 0,
      timeAgo: '2 ngày trước',
    ),
    FriendRequest(
      id: '5',
      name: 'Hoàng Văn E',
      avatarUrl: 'https://randomuser.me/api/portraits/men/15.jpg',
      mutualFriends: 3,
      timeAgo: '3 ngày trước',
    ),
    FriendRequest(
      id: '6',
      name: 'Ngô Thị F',
      avatarUrl: 'https://randomuser.me/api/portraits/women/16.jpg',
      mutualFriends: 1,
      timeAgo: '1 tuần trước',
    ),
  ];

  // Danh sách id của các lời mời đã xử lý
  final List<String> _processedRequests = [];

  @override
  Widget build(BuildContext context) {
    // Lọc ra các lời mời chưa xử lý
    final activeRequests = _friendRequests
        .where((request) => !_processedRequests.contains(request.id))
        .toList();

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
            // Xử lý khi nhấn nút quay lại
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quay lại màn hình trước')),
            );
          },
        ),
      ),
      body: activeRequests.isEmpty
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
              '${activeRequests.length} lời mời kết bạn',
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
            itemCount: activeRequests.length,
            itemBuilder: (context, index) {
              final request = activeRequests[index];
              return FriendRequestCard(
                request: request,
                onAccept: () {
                  setState(() {
                    _processedRequests.add(request.id);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã chấp nhận lời mời từ ${request.name}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                onDecline: () {
                  setState(() {
                    _processedRequests.add(request.id);
                  });
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
    Key? key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

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
                      const SizedBox(height: 4),
                      if (request.mutualFriends > 0)
                        Text(
                          '${request.mutualFriends} bạn chung',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        request.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
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

class FriendRequest {
  final String id;
  final String name;
  final String avatarUrl;
  final int mutualFriends;
  final String timeAgo;

  FriendRequest({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.mutualFriends,
    required this.timeAgo,
  });
}