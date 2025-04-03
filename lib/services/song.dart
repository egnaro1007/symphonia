

import '../models/song.dart';

class SongOperations {
  SongOperations._();

  static List<Song> getSongs() {
    return <Song>[
      Song(rank: "1", title: "Sự nghiệp chướng", artist: "Pháo", imagePath: "assets/images/phao.jpg"),
      Song(rank: "2", title: "Sài Gòn đau lòng quá", artist: "Hứa Kim Tuyền x Hoàng Duyên", imagePath: "assets/images/hua_kim_tuyen.jpg"),
      Song(rank: "3", title: "Cưới thôi", artist: "Masew x B Ray x Han Sara", imagePath: "assets/images/masew.jpg"),
      Song(rank: "4", title: "Thức giấc", artist: "Da LAB", imagePath: "assets/images/da_lab.jpg"),
      Song(rank: "5", title: "Sài Gòn hôm nay mưa", artist: "JSOL x Hoàng Duyên", imagePath: "assets/images/jsol.jpg"),
      Song(rank: "6", title: "Có hẹn với thanh xuân", artist: "Monstar", imagePath: "assets/images/monstar.jpg"),
      Song(rank: "7", title: "Thích thì đến", artist: "Masew x Bray x TAP", imagePath: "assets/images/masew.jpg"),
      Song(rank: "8", title: "Cưới thôi", artist: "Masew x B Ray x Han Sara", imagePath: "assets/images/masew.jpg"),
      Song(rank: "9", title: "Thức giấc", artist: "Da LAB", imagePath: "assets/images/da_lab.jpg"),
      Song(rank: "10", title: "Sài Gòn hôm nay mưa", artist: "JSOL x Hoàng Duyên", imagePath: "assets/images/jsol.jpg"),
      Song(rank: "11", title: "Có hẹn với thanh xuân", artist: "Monstar", imagePath: "assets/images/monstar.jpg"),
      Song(rank: "12", title: "Thích thì đến", artist: "Masew x Bray x TAP", imagePath: "assets/images/masew.jpg"),
    ];
  }
}