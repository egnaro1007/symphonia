class Searching {
  Searching._();

  // Mock function for search suggestions
  static List<String> searchSuggestions(String word) {
    // This would typically be an API call or database query
    if (word.toLowerCase().contains("sự")) {
      return [
        "sự nghiệp chướng",
        "sự thật sau một lời hứa",
        "sự thật đã bỏ quên"
      ];
    } else if (word.isEmpty) {
      return [];
    } else {
      // Return different suggestions for different searches
      return ["$word mới", "$word hay", "$word nổi tiếng"];
    }
  }

  // Mock function for search results
  static List<Map<String, dynamic>> searchResults(String word) {
    // This would typically be an API call or database query
    if (word.toLowerCase().contains("sự")) {
      return [
        {
          "type": "song",
          "title": "SỰ NGHIỆP CHƯỚNG",
          "artist": "Pháo",
          "image": "assets/artist1.jpg"
        },
        {
          "type": "artist",
          "name": "Pháo",
          "subtitle": "Nghệ sĩ • 92K quan tâm",
          "image": "assets/artist2.jpg"
        },
        {
          "type": "song",
          "title": "Sự Thật Sau Một Lời Hứa",
          "artist": "Chi Dân",
          "image": "assets/artist3.jpg"
        }
      ];
    } else if (word.isEmpty) {
      return [];
    } else {
      // Return different results for different searches
      return [
        {
          "type": "song",
          "title": word.toUpperCase(),
          "artist": "Various Artists",
          "image": "assets/artist4.jpg"
        },
        {
          "type": "artist",
          "name": word,
          "subtitle": "Nghệ sĩ • Search Result",
          "image": "assets/artist5.jpg"
        }
      ];
    }
  }
}