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
  final DatabaseReference _companyRef = FirebaseDatabase.instance.ref("companies");

  List<String> _companySuggestions = [];
  bool _isLoadingCompanies = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  void _loadCompanies() async {
    // Fetch existing companies from Firebase
    final companiesSnapshot = await _companyRef.get();
    if (companiesSnapshot.exists) {
      final companies = companiesSnapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _companySuggestions = companies.keys.map((e) => e.toString()).toList();
        _isLoadingCompanies = false;
      });
    } else {
      setState(() {
        _companySuggestions = [];
        _isLoadingCompanies = false;
      });
    }
  }

  void _submitPost() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Check if company name is already in the Firebase "companies" node
      final companyExists = _companySuggestions.contains(_companyName);

      // Create a new post entry
      final newPostRef = _databaseRef.push();
      try {
        await newPostRef.set({
          'companyName': _companyName,
          'postedBy': widget.user.displayName,
          'content': _postContent,
          'likes': 0,
          'likedUsers': [],
          'timestamp': DateTime.now().toIso8601String(),
        });

        // If the company does not exist, store it in the "companies" node
        if (!companyExists) {
          await _companyRef.child(_companyName).set({
            'companyName': _companyName,
          });
        }

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
        child: _isLoadingCompanies
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _companySuggestions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  setState(() {
                    _companyName = selection;
                  });
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
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
                  );
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
