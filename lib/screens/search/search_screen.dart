import 'package:flutter/material.dart';
import 'package:symphonia/services/searching.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: "sự");
  List<String> _searchSuggestions = [];
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Initial search when the page loads
    _updateSearchResults(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearchResults(String query) {
    setState(() {
      _searchSuggestions = Searching.searchSuggestions(query);
      _searchResults = Searching.searchResults(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    // back to previous screen
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search",
                            ),
                            onChanged: (value) {
                              _updateSearchResults(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _updateSearchResults("");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          // Search results
          Expanded(
            child: _searchController.text.isEmpty
                ? Center(
              child: Text("Enter text to search"),
            )
                : ListView(
              children: [
                // Suggestions
                ..._searchSuggestions.map((suggestion) =>
                    _buildSearchSuggestion(suggestion)),

                // Results
                ..._searchResults.map((result) {
                  if (result["type"] == "song") {
                    return _buildSearchResult(
                      result["title"],
                      result["artist"],
                      result["image"],
                    );
                  } else if (result["type"] == "artist") {
                    return _buildArtistProfile(
                      result["name"],
                      result["subtitle"],
                      result["image"],
                    );
                  }
                  return Container();
                }),

                if (_searchSuggestions.isNotEmpty || _searchResults.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        "Xem tất cả kết quả",
                        style: TextStyle(
                          color: Colors.purple,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _buildSearchSuggestion(String text) {
    return ListTile(
      leading: Icon(Icons.search, color: Colors.grey),
      title: Text(text),
      dense: true,
      onTap: () {
        setState(() {
          _searchController.text = text;
          _updateSearchResults(text);
        });
      },
    );
  }

  Widget _buildSearchResult(String title, String artist, String imagePath) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Icon(Icons.music_note),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_outline),
          SizedBox(width: 16),
          Icon(Icons.more_vert),
        ],
      ),
    );
  }

  Widget _buildArtistProfile(String name, String subtitle, String imagePath) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: Icon(Icons.person),
        ),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right),
    );
  }
}
