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
            'ratings': value['ratings'] ?? 0.0,
            'ratedBy': List<String>.from(value['ratedBy'] ?? []),
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
    _databaseRef.child(postKey).remove().then((_) {
      // Show SnackBar on successful deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Update the state to remove the post from the list
      setState(() {
        myPosts.removeWhere((post) => post['key'] == postKey);
      });
    }).catchError((error) {
      // Handle any errors that might occur during deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete post: $error'),
          duration: Duration(seconds: 2),
        ),
      );
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

  void _onRatePressed(int index, double rating) {
    final postKey = myPosts[index]['key'];
    final ratedBy = myPosts[index]['ratedBy'];
    final currentRating = myPosts[index]['ratings'];

    if (!ratedBy.contains(widget.user.uid)) {
      ratedBy.add(widget.user.uid);

      // Calculate the new average rating
      final totalRaters = ratedBy.length;
      final newRating = (currentRating * (totalRaters - 1) + rating) / totalRaters;

      _databaseRef.child(postKey).update({
        'ratings': newRating,
        'ratedBy': ratedBy,
      });

      // Update the UI
      setState(() {
        myPosts[index]['ratings'] = newRating;
        myPosts[index]['ratedBy'] = ratedBy;
      });
    }
  }

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
          ? const Center(child: Text('No posts to display.'),)
          : ListView.builder(
        itemCount: myPosts.length,
        itemBuilder: (context, index) {
          List<String> likedBy = List<String>.from(myPosts[index]['likedBy'] ?? []);
          List<String> dislikedBy = List<String>.from(myPosts[index]['dislikedBy'] ?? []);

          // Default values for likes, dislikes, and ratings if null
          int likes = myPosts[index]['likes'] ?? 0;
          int dislikes = myPosts[index]['dislikes'] ?? 0;
          double ratings = myPosts[index]['ratings'] ?? 0.0;

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
                        // Popup for Like button
                        PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext context) {
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
                              color: likedBy.contains(widget.user.uid) ? Colors.green : Colors.grey,
                            ),
                            onPressed: myPosts[index]['likedBy'].contains(widget.user.displayName) ||
                                myPosts[index]['dislikedBy'].contains(widget.user.displayName)
                                ? null
                                : () => _onLikePressed(index),
                          ),
                        ),
                        Text('${myPosts[index]['likes']}'),

                        // Popup for Dislike button
                        PopupMenuButton<String>(
                          onSelected: (value) {},
                          itemBuilder: (BuildContext context) {
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
                              color: dislikedBy.contains(widget.user.uid) ? Colors.red : Colors.grey,
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
                          Row(
                            children: [
                              Text(
                                myPosts[index]['companyName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(width: 8),
                              // Display average rating
                              Row(
                                children: List.generate(5, (ratingIndex) {
                                  return GestureDetector(
                                    onTap: () => _onRatePressed(index, ratingIndex + 1), // User can tap on stars
                                    child: Icon(
                                      Icons.star,
                                      color: (ratingIndex < ratings) ? Colors.yellow : Colors.grey,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Posted by: ${myPosts[index]['postedBy'] ?? ''}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(myPosts[index]['content'] ?? ''),
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
