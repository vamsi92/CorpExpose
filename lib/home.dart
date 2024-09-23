import 'package:corp_expose/post.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Post> posts = [
    Post("Company A", "Alice", "Why I would reject Company A due to poor work culture.", 5),
    Post("Company B", "Bob", "Issues with Company B related to management.", 3),
    Post("Company C", "Charlie", "Concerns about Company C's lack of transparency.", 8),
    Post("Company D", "Diana", "Negative experiences with Company D's customer service.", 2),
    Post("Company E", "Rob", "Negative experiences with Company D's customer service.", 2),
    Post("Company F", "Kir", "Negative experiences with Company D's customer service.", 2),
    Post("Company G", "Rabo", "Negative experiences with Company D's customer service.", 2),
    Post("Company H", "Jonny", "Negative experiences with Company D's customer service.", 2),
    Post("Company I", "Melane", "Negative experiences with Company D's customer service.", 2),
    Post("Company J", "Krish", "Negative experiences with Company D's customer service.", 2),
    Post("Company K", "Chris", "Negative experiences with Company D's customer service.", 2),
  ];

  List<Post> filteredPosts = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    filteredPosts = posts;
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredPosts = posts.where((post) {
        return post.companyName.toLowerCase().contains(searchQuery) ||
            post.content.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  void _onLikePressed(int index) {
    setState(() {
      filteredPosts[index] = Post(
        filteredPosts[index].companyName,
        filteredPosts[index].postedBy,
        filteredPosts[index].content,
        filteredPosts[index].likes + 1,
      );
    });
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/auth'); // Redirect to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by company name or keywords...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white60),
                icon: Icon(Icons.search, color: Colors.white),
              ),
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
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
                    filteredPosts[index].companyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Posted by: ${filteredPosts[index].postedBy}",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(filteredPosts[index].content),
                  const Divider(thickness: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _onLikePressed(index),
                      ),
                      Text('${filteredPosts[index].likes} Likes'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Post'),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout (${widget.user.displayName})', // Show the logged-in username here
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 2) {
            _signOut(); // Handle sign-out on the logout button
          }
        },
      ),
    );
  }
}
