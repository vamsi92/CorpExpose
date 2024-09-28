import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyPostsScreen extends StatefulWidget {
  final User user;

  const MyPostsScreen({Key? key, required this.user}) : super(key: key);

  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("posts");
  List<Map<String, dynamic>> myPosts = [];

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  void _fetchMyPosts() async {
    final snapshot = await _databaseRef.orderByChild('postedBy').equalTo(widget.user.displayName).once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        myPosts.add({
          'key': key,
          'companyName': value['companyName'],
          'postedBy': value['postedBy'],
          'content': value['content'],
          'likes': value['likes'] ?? 0,
          'likedBy': value['likedBy'] ?? [],
          'dislikedBy': value['dislikedBy'] ?? [],
          'dislikes': value['dislikes'] ?? 0,
        });
      });
      setState(() {});
    } else {
      setState(() {
        myPosts = [];
      });
    }
  }

  void _deletePost(String postKey) {
    _databaseRef.child(postKey).remove();
    setState(() {
      myPosts.removeWhere((post) => post['key'] == postKey);
    });
  }

  // Replace this with your like and dislike logic
  void _onLikePressed(int index) {}
  void _onDislikePressed(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Posts')),
      body: myPosts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: myPosts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Like/Dislike column
                    Column(
                      children: [
                        // Like button
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: myPosts[index]['likedBy'].contains(widget.user.uid) ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _onLikePressed(index),
                        ),
                        Text('${myPosts[index]['likes']}'),
                        // Dislike button
                        IconButton(
                          icon: Icon(
                            Icons.thumb_down,
                            color: myPosts[index]['dislikedBy'].contains(widget.user.uid) ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _onDislikePressed(index),
                        ),
                        Text('${myPosts[index]['dislikes']}'),
                      ],
                    ),
                    Container(
                      width: 1,
                      color: Colors.grey,
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    // Post content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  myPosts[index]['companyName'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              // Delete button aligned to the right
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePost(myPosts[index]['key']),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text("Posted by: ${myPosts[index]['postedBy']}", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(myPosts[index]['content']),
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
    );
  }
}
