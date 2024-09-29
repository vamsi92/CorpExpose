import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String initialContent;

  EditPostScreen({required this.postId, required this.initialContent});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final int _characterLimit = 1000; // Set your character limit here
  int _currentLength = 0; // Variable to keep track of current length

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.initialContent; // Set initial content
    _currentLength = widget.initialContent.length; // Initialize current length

    // Listen for changes in the text field
    _contentController.addListener(() {
      setState(() {
        _currentLength = _contentController.text.length; // Update current length on change
      });
    });
  }

  Future<bool> _updatePost() async {
    try {
      // Update the post in Firebase
      DatabaseReference postRef = FirebaseDatabase.instance.ref(
          'posts/${widget.postId}');

      await postRef.update({
        'content': _contentController.text,
      });
      return true;
    }catch (e) {
      // Show an error message if the update fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post.')),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _contentController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              maxLength: _characterLimit, // Set the max length here
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Post Content',
                counterText: '$_currentLength / $_characterLimit', // Display current length
              ),
              maxLines: 5,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Set your desired background color
                foregroundColor: Colors.white, // Set your desired text color
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjust padding
              ),
              onPressed: () async {
                bool updated = await _updatePost();
                if (updated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post updated successfully.')),
                  );
                  Navigator.pop(context, true); // Pass true back to indicate update
                }
              },
              child: const Text(
                'Save Changes',
                style: TextStyle(fontSize: 16), // Customize font size if needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
