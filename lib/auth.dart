import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await signInWithGoogle(context);
          },
          child: Text('Sign in with Google'),
        ),
      ),
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    // Trigger the authentication flow
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // If the sign-in is successful, navigate to home screen
      if (userCredential.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen(user: userCredential.user!)),
        );
      }
    } catch (e) {
      print(e);
    }
  }
}
