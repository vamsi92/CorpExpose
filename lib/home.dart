import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

        final List<Map<String, dynamic>> loadedPosts = [];
        data.forEach((key, value) {
          loadedPosts.add({
            'companyName': value['companyName'] ?? 'Unknown Company',
            'postedBy': value['postedBy'] ?? 'Anonymous',
            'content': value['content'] ?? 'No Content',
            'likes': value['likes'] ?? 0,
            'dislikes': value['dislikes'] ?? 0,
            'likedBy': List<String>.from(value['likedBy'] ?? []),
            'dislikedBy': List<String>.from(value['dislikedBy'] ?? []),
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
    final dislikedBy = filteredPosts[index]['dislikedBy'];

    // Check if the user has already liked or disliked this post
    if (!likedBy.contains(widget.user.uid) && !dislikedBy.contains(widget.user.uid)) {
      likedBy.add(widget.user.uid); // Add the user's ID to the likedBy list
      _databaseRef.child(postKey).update({
        'likes': currentLikes + 1,
        'likedBy': likedBy,
      });
    }
  }

  void _onDislikePressed(int index) {
    final postKey = filteredPosts[index]['key'];
    final currentDislikes = filteredPosts[index]['dislikes'];
    final likedBy = filteredPosts[index]['likedBy'];
    final dislikedBy = filteredPosts[index]['dislikedBy'];

    // Check if the user has already disliked or liked this post
    if (!dislikedBy.contains(widget.user.uid) && !likedBy.contains(widget.user.uid)) {
      dislikedBy.add(widget.user.uid); // Add the user's ID to the dislikedBy list
      _databaseRef.child(postKey).update({
        'dislikes': currentDislikes + 1,
        'dislikedBy': dislikedBy,
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
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  ),
                  style: const TextStyle(color: Colors.black),
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 120), // Ensuring proper size
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Like/Dislike column
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.thumb_up,
                                  color: filteredPosts[index]['likedBy'].contains(widget.user.uid)
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                onPressed: () => _onLikePressed(index),
                              ),
                              Text('${filteredPosts[index]['likes']}'),
                              IconButton(
                                icon: Icon(
                                  Icons.thumb_down,
                                  color: filteredPosts[index]['dislikedBy'].contains(widget.user.uid)
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: () => _onDislikePressed(index),
                              ),
                              Text('${filteredPosts[index]['dislikes']}'),
                            ],
                          ),
                          // Vertical border as a divider
                          Container(
                            width: 1, // Width of the divider
                            color: Colors.grey, // Color of the divider
                            height: 120, // Height of the divider
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                          ),
                          // Post content
                          Expanded(
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
                              ],
                            ),
                          ),
                        ],
                      ),
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
