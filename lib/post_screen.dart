import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PostScreen extends StatefulWidget {
  final User user;

  const PostScreen({super.key, required this.user});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _companyName = "";
  String _postContent = "";
  final int _maxChars = 1000;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref("posts");

  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create a new post entry
      final newPostRef = _databaseRef.push();
      try {
      await newPostRef.set({
        'companyName': _companyName,
        'postedBy': widget.user.displayName,
        'content': _postContent,
        'likes': 0,
        'likedUsers': [], // Initialize likedUsers as an empty list
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Show success Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post submitted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context); // Go back to the homepage after posting
      } catch (e) {
        // Show error Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Company name cannot be empty';
                  }
                  return null;
                },
                onSaved: (value) {
                  _companyName = value!;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLength: _maxChars,
                decoration: const InputDecoration(
                  labelText: 'Write your post...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Post cannot be empty';
                  }
                  return null;
                },
                onSaved: (value) {
                  _postContent = value!;
                },
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitPost,
                child: const Text('Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
