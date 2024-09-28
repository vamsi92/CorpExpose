import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'edit_post.dart';

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
    final snapshot = await _databaseRef
        .orderByChild('postedBy')
        .equalTo(widget.user.displayName)
        .once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      // Clear previous posts to avoid duplicates
      setState(() {
        myPosts.clear();
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
      });
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


  void _onLikePressed(int index) async {
    String postKey = myPosts[index]['key'];
    String userId = widget.user.displayName ?? 'Unknown User';

    // Update locally first for immediate UI feedback
    setState(() {
      myPosts[index]['likes'] += 1;
      myPosts[index]['likedBy'].add(userId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You liked this post!'),
        duration: Duration(seconds: 1), // Optional: control how long the SnackBar is visible
      ),
    );

    // Update Firebase asynchronously
    await _databaseRef.child(postKey).runTransaction((currentData){
      if (currentData  != null) {
        Map<String, dynamic> post = Map<String, dynamic>.from(currentData as Map);
        int currentLikes = post['likes'] ?? 0;
        List<String> likedBy = List<String>.from(post['likedBy'] ?? []);
        if (!likedBy.contains(userId)) {
          likedBy.add(userId);
          post['likes'] = currentLikes + 1;
          post['likedBy'] = likedBy;
        }
        return Transaction.success(post);
      }
      return Transaction.abort();
    });
  }

  void _onDislikePressed(int index) async {
    String postKey = myPosts[index]['key'];
    String userId = widget.user.displayName ?? 'Unknown User';

    // Update locally first for immediate UI feedback
    setState(() {
      myPosts[index]['dislikes'] += 1;
      myPosts[index]['dislikedBy'].add(userId);
    });

    // Show SnackBar after clicking dislike
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You disliked this post!'),
        duration: Duration(seconds: 1), // Optional: control how long the SnackBar is visible
      ),
    );

    // Update Firebase asynchronously
    await _databaseRef.child(postKey).runTransaction((currentData) {
      if (currentData != null) {
        Map<String, dynamic> post = Map<String, dynamic>.from(currentData as Map);
        int currentDislikes = post['dislikes'] ?? 0;
        List<String> dislikedBy = List<String>.from(post['dislikedBy'] ?? []);
        if (!dislikedBy.contains(userId)) {
          dislikedBy.add(userId);
          post['dislikes'] = currentDislikes + 1;
          post['dislikedBy'] = dislikedBy;
        }
        return Transaction.success(post);
      }
      return Transaction.abort();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Posts'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
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
                        PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext context) {
                            List<String> likedBy = List<String>.from(myPosts[index]['likedBy']);
                            if (likedBy.isEmpty) {
                              return [
                                const PopupMenuItem<String>(
                                  value: '',
                                  child: Text('No one liked this post yet.'),
                                ),
                              ];
                            } else {
                              return likedBy.map((user) {
                                return PopupMenuItem<String>(
                                  value: user,
                                  child: Text(user), // Display user names who liked the post
                                );
                              }).toList();
                            }
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: myPosts[index]['likedBy'].contains(widget.user.uid)
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: myPosts[index]['likedBy'].contains(widget.user.displayName) ||
                                myPosts[index]['dislikedBy'].contains(widget.user.displayName)
                                ? null
                                : () => _onLikePressed(index),
                          ),),
                        Text('${myPosts[index]['likes']}'),
// Popup for Dislike button
                        PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext context) {
                            List<String> dislikedBy = List<String>.from(myPosts[index]['dislikedBy']);
                            if (dislikedBy.isEmpty) {
                              return [
                                const PopupMenuItem<String>(
                                  value: '',
                                  child: Text('No one disliked this post yet.'),
                                ),
                              ];
                            } else {
                              return dislikedBy.map((user) {
                                return PopupMenuItem<String>(
                                  value: user,
                                  child: Text(user), // Display user names who disliked the post
                                );
                              }).toList();
                            }
                          },
                          child: IconButton(
                            icon: Icon(
                              Icons.thumb_down,
                              color: myPosts[index]['dislikedBy'].contains(widget.user.uid)
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: myPosts[index]['dislikedBy'].contains(widget.user.displayName) ||
                                myPosts[index]['likedBy'].contains(widget.user.displayName)
                                ? null
                                : () => _onDislikePressed(index),
                          ),),
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
                          Text(
                            myPosts[index]['companyName'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Posted by: ${myPosts[index]['postedBy']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(myPosts[index]['content']),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      color: Colors.grey,
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    ),
                    // Edit/Delete column
                    Column(
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            bool? isUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditPostScreen(
                                  postId: myPosts[index]['key'],
                                  initialContent: myPosts[index]['content'],
                                ),
                              ),
                            );
                            if (isUpdated == true) {
                              // Reload the posts data
                              _fetchMyPosts(); // Call your method to reload posts
                            }
                          },
                        ),
                        const SizedBox(height: 8), // Spacing between buttons
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePost(myPosts[index]['key']),
                        ),
                      ],
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
