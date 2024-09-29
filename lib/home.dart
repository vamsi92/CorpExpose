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
  String loggedInUser = "";

  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  String? _lastFetchedKey; // Used for pagination

  // Define a key for the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Navigation to My Posts page
  void _navigateToMyPosts() async {
    final result = await Navigator.pushNamed(context, '/myPosts');
    if (result == true) {
      _fetchPosts(); // Reload posts when coming back from "My Posts"
    }
  }

  @override
  void initState() {
    super.initState();

    loggedInUser = widget.user.displayName ?? 'Unknown User';
    _fetchPosts();
    _scrollController.addListener(_onScroll); // Attach scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  void _onScroll() {
    // Check if the user has scrolled to the bottom of the list
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoadingMore) {
      _loadMorePosts(); // Load more posts
    }
  }

  void _loadMorePosts() {
    if (_lastFetchedKey != null) {
      _fetchPosts(startAfterKey: _lastFetchedKey); // Fetch the next set of posts
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchPosts(); // Fetch the posts when dependencies change
  }


  void _fetchPosts({String? startAfterKey}) async {
    try {
      setState(() {
        _isLoadingMore = true;
        if (startAfterKey == null) {
          posts.clear(); // Clear existing posts when starting a new fetch
        }
      });

      // Create the query
      Query query = _databaseRef.orderByKey().limitToFirst(10);
      if (startAfterKey != null) {
        query = _databaseRef.orderByKey().startAfter(startAfterKey).limitToFirst(10);
      }

      // Fetch the posts
      query.onValue.listen((event) {
        if (event.snapshot.value != null) {
          final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
          final List<Map<String, dynamic>> loadedPosts = [];
          final Set<String> existingKeys = Set<String>.from(posts.map((post) => post['key'])); // Create a set of existing keys

          data.forEach((key, value) {
            // Only add the post if its key is not already in the existingKeys set
            if (!existingKeys.contains(key)) {
              loadedPosts.add({
                'companyName': value['companyName'] ?? 'Unknown Company',
                'postedBy': value['postedBy'] ?? 'Anonymous',
                'content': value['content'] ?? 'No Content',
                'likes': value['likes'] ?? 0,
                'dislikes': value['dislikes'] ?? 0,
                'ratings': value['ratings'] ?? 0.0,
                'ratedBy': List<String>.from(value['ratedBy'] ?? []),
                'likedBy': List<String>.from(value['likedBy'] ?? []),
                'dislikedBy': List<String>.from(value['dislikedBy'] ?? []),
                'key': key,
              });
            }
          });

          setState(() {
            posts.addAll(loadedPosts); // Add only non-duplicate posts
            filteredPosts = posts;

            if (loadedPosts.isNotEmpty) {
              _lastFetchedKey = loadedPosts.last['key']; // Save the last fetched post's key
            }

            _isLoadingMore = false;
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
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

  void _onLikePressed(int index) async {
    String postKey = filteredPosts[index]['key'];
    String userId = widget.user.displayName ?? 'Unknown User';

    // Update locally first for immediate UI feedback
    setState(() {
      filteredPosts[index]['likes'] += 1;
      filteredPosts[index]['likedBy'].add(userId);
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
    String postKey = filteredPosts[index]['key'];
    String userId = widget.user.displayName ?? 'Unknown User';

    // Update locally first for immediate UI feedback
    setState(() {
      filteredPosts[index]['dislikes'] += 1;
      filteredPosts[index]['dislikedBy'].add(userId);
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
    final postKey = filteredPosts[index]['key'];
    final ratedBy = filteredPosts[index]['ratedBy'];
    final currentRating = filteredPosts[index]['ratings'];

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
        filteredPosts[index]['ratings'] = newRating;
        filteredPosts[index]['ratedBy'] = ratedBy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white, // Change to a white background for a clean UI
        elevation: 2, // Slight shadow for the app bar
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
                  color: Colors.grey[200], // Light background for the search box
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                ),
                child: TextField(
                  onChanged: _onSearchChanged,
                  cursorColor: Colors.black, // Black cursor
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8.0), // Padding for larger icon
                      child: Icon(
                        Icons.search,
                        color: Colors.grey[700],
                        size: 28, // Larger icon for better visibility
                      ),
                    ),
                    hintText: 'Search companies or posts...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), // Padding for better touch experience
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16), // Larger, clearer font
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.black), // Icon for My Posts
            onPressed: () {
              _navigateToMyPosts(); // Function to navigate to My Posts page
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: posts.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loading while fetching posts
          : Column(
        children: [
          Expanded(
            child: filteredPosts.isEmpty
                ? const Center(child: Text('No posts available.'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: filteredPosts.length,
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
// Popup for Like button
                              PopupMenuButton<String>(
                                onSelected: (value) {},
                                itemBuilder: (BuildContext context) {
                                  List<String> likedBy = List<String>.from(filteredPosts[index]['likedBy']);
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
                                    color: filteredPosts[index]['likedBy'].contains(widget.user.uid)
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onPressed: filteredPosts[index]['likedBy'].contains(widget.user.displayName) ||
                                      filteredPosts[index]['dislikedBy'].contains(widget.user.displayName)
                                      ? null
                                      : () => _onLikePressed(index),
                                ),),
                              Text('${filteredPosts[index]['likes']}'),
// Popup for Dislike button
                              PopupMenuButton<String>(
                                onSelected: (value) {},
                                itemBuilder: (BuildContext context) {
                                  List<String> dislikedBy = List<String>.from(filteredPosts[index]['dislikedBy']);
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
                                    color: filteredPosts[index]['dislikedBy'].contains(widget.user.uid)
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: filteredPosts[index]['dislikedBy'].contains(widget.user.displayName) ||
                                      filteredPosts[index]['likedBy'].contains(widget.user.displayName)
                                      ? null
                                      : () => _onDislikePressed(index),
                                ),),
                              Text('${filteredPosts[index]['dislikes']}'),
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
                                // Company name and rating side by side
                                Row(
                                  children: [
                                    Text(
                                      filteredPosts[index]['companyName'],
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
                                            color: (ratingIndex < filteredPosts[index]['ratings'])
                                                ? Colors.yellow
                                                : Colors.grey,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
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
      floatingActionButton: Stack(
        children: <Widget>[
          // Refresh Button
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'refresh', // Unique tag for the button
              child: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  posts.clear(); // Clear existing posts
                  filteredPosts.clear(); // Clear filtered posts
                  _lastFetchedKey = null; // Reset pagination
                  _fetchPosts(); // Fetch posts again
                });
                // Show a Snackbar message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Posts refreshed!'), // Message to display
                    duration: Duration(seconds: 2), // Duration to show the Snackbar
                  ),
                );
              },
            ),
          ),
          // Add Post Button
          Positioned(
            bottom: 16,
            right: 80, // Adjust position as needed
            child: FloatingActionButton(
              heroTag: 'add', // Unique tag for the button
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(context, '/post');
              },
            ),
          ),
        ],
      ),
    );
  }
}
