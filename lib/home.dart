import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("posts");
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> filteredPosts = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  void _fetchPosts() {
    _databaseRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;

        if (data.isEmpty) {
          setState(() {
            posts = [];
            filteredPosts = [];
          });
          return;
        }

        final List<Map<String, dynamic>> loadedPosts = [];
        data.forEach((key, value) {
          loadedPosts.add({
            'companyName': value['companyName'] ?? 'Unknown Company',
            'postedBy': value['postedBy'] ?? 'Anonymous',
            'content': value['content'] ?? 'No Content',
            'likes': value['likes'] ?? 0,
            'likedBy': List<String>.from(value['likedBy'] ?? []), // List of user IDs who liked this post
            'key': key,
          });
        });

        setState(() {
          posts = loadedPosts;
          filteredPosts = loadedPosts;
        });
      } else {
        setState(() {
          posts = [];
          filteredPosts = [];
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      filteredPosts = posts.where((post) {
        final companyName = post['companyName'].toLowerCase();
        final content = post['content'].toLowerCase();
        return companyName.contains(query.toLowerCase()) || content.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _onLikePressed(int index) {
    final postKey = filteredPosts[index]['key'];
    final currentLikes = filteredPosts[index]['likes'];
    final likedBy = filteredPosts[index]['likedBy'];

    // Check if the user has already liked this post
    if (!likedBy.contains(widget.user.uid)) {
      likedBy.add(widget.user.uid); // Add the user's ID to the likedBy list
      _databaseRef.child(postKey).update({
        'likes': currentLikes + 1,
        'likedBy': likedBy, // Update the likedBy list in the database
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/CX.png',
              height: 48,
            ),
            const SizedBox(width: 16), // Space between title and search bar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Search bar background color
                  borderRadius: BorderRadius.circular(20.0), // Rounded corners
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)], // Soft shadow effect
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey), // Search icon
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[600]), // Hint text style
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  style: const TextStyle(color: Colors.black), // Text color in the search bar
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(child: Text('No posts available.'))
                : ListView.builder(
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filteredPosts[index]['companyName'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Posted by: ${filteredPosts[index]['postedBy']}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(filteredPosts[index]['content']),
                        const Divider(thickness: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              onPressed: () => _onLikePressed(index),
                            ),
                            Text('${filteredPosts[index]['likes']} Likes'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/post');
        },
      ),
    );
  }
}
