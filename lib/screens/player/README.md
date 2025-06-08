# Player System Architecture

Hệ thống player đã được tách riêng thành 3 components chính để hỗ trợ tốt hơn cho nhạc trực tuyến và nhạc đã tải xuống.

## Cấu trúc Files

### 1. `adaptive_player_screen.dart`
- **Mục đích**: Wrapper chính quyết định sử dụng player nào
- **Chức năng**: 
  - Kiểm tra trạng thái download của bài hát hiện tại
  - Tự động chuyển đổi giữa OnlinePlayerScreen và DownloadedPlayerScreen
  - Hiển thị loading indicator khi đang kiểm tra trạng thái

### 2. `online_player_screen.dart`
- **Mục đích**: Player cho nhạc trực tuyến
- **Tính năng đầy đủ**:
  - ✅ Nút tim (like/unlike)
  - ✅ Nút thêm vào playlist
  - ✅ Selector chất lượng âm thanh (có thể click để thay đổi)
  - ✅ Dialog chọn chất lượng với danh sách các chất lượng có sẵn
  - ✅ Hiển thị kích thước file cho mỗi chất lượng

### 3. `downloaded_player_screen.dart`
- **Mục đích**: Player cho nhạc đã tải xuống
- **Tính năng được điều chỉnh**:
  - ❌ Không có nút tim (không thể like nhạc offline)
  - ❌ Không có nút thêm vào playlist (không thể thêm nhạc offline vào playlist online)
  - ✅ Hiển thị chất lượng âm thanh (không thể click, chỉ hiển thị)
  - ✅ Icon download để chỉ ra đây là nhạc đã tải xuống
  - ✅ Chất lượng hiển thị dựa trên chất lượng thực tế khi tải xuống

### 4. `player_screen.dart` (Legacy)
- **Trạng thái**: Giữ lại để tương thích ngược
- **Khuyến nghị**: Sử dụng `adaptive_player_screen.dart` cho tất cả implementation mới

## Cách sử dụng

### Trong code mới
```dart
// Thay vì sử dụng PlayerScreen
AdaptivePlayerScreen(closePlayer: _togglePlayer)
```

### Logic hoạt động
1. `AdaptivePlayerScreen` được khởi tạo
2. Kiểm tra `DownloadController.isDownloaded(songId)`
3. Nếu `true` → hiển thị `DownloadedPlayerScreen`
4. Nếu `false` → hiển thị `OnlinePlayerScreen`
5. Tự động cập nhật khi chuyển bài hát

## Sự khác biệt UI

### Online Player
```
[❤️]  [320kbps ▼]  [📋+]
```
- Nút tim: Có thể like/unlike
- Chất lượng: Có thể click để mở dialog chọn chất lượng
- Nút playlist: Có thể thêm vào playlist

### Downloaded Player
```
      [📥 320kbps]
```
- Chỉ hiển thị chất lượng với icon download
- Không thể thay đổi chất lượng
- Không có nút like và add to playlist

## Dependencies

### OnlinePlayerScreen
- `LikeOperations` - Xử lý like/unlike
- `PlayListOperations` - Xử lý thêm vào playlist
- `PlayerController.changeAudioQuality()` - Thay đổi chất lượng

### DownloadedPlayerScreen
- `DownloadController.getDownloadInfo()` - Lấy thông tin chất lượng đã tải

### AdaptivePlayerScreen
- `DownloadController.isDownloaded()` - Kiểm tra trạng thái download
- `PlayerController.onSongChange` - Lắng nghe thay đổi bài hát

## Migration Guide

### Từ PlayerScreen sang AdaptivePlayerScreen
1. Thay đổi import:
```dart
// Cũ
import 'package:symphonia/screens/player/player_screen.dart';

// Mới  
import 'package:symphonia/screens/player/adaptive_player_screen.dart';
```

2. Thay đổi widget:
```dart
// Cũ
PlayerScreen(closePlayer: _togglePlayer)

// Mới
AdaptivePlayerScreen(closePlayer: _togglePlayer)
```

## Lưu ý kỹ thuật

- Tất cả 3 player đều sử dụng cùng `PlayerController` instance
- Tab system (lyrics, playlist, related) hoạt động giống nhau trên cả 2 player
- Loading state được xử lý trong `AdaptivePlayerScreen`
- Error handling cho việc kiểm tra download status
- Tự động fallback về online player nếu có lỗi khi kiểm tra download status 