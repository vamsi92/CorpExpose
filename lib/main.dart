import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'home.dart';
import 'post_screen.dart';
import 'firebase_options.dart';
import 'my_posts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CorpExpose',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final User? user = snapshot.data;
            if (user != null) {
              // User is logged in, navigate to HomeScreen
              return HomeScreen(user: user);
            } else {
              // User is not logged in, navigate to AuthScreen
              return AuthScreen();
            }
          } else {
            // Show a loading indicator while waiting for authentication state
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(user: FirebaseAuth.instance.currentUser!),
        '/post': (context) => PostScreen(user: FirebaseAuth.instance.currentUser!),
        '/myPosts': (context) => MyPostsScreen(user: FirebaseAuth.instance.currentUser!),
      },
    );
  }
}
