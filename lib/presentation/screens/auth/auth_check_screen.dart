import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../providers/app_provider.dart';
import '../home/main_shell.dart';
import 'auth_screen.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Check if user is authenticated
        if (FirebaseAuth.instance.currentUser != null) {
          // User is authenticated, navigate to home
          return const MainShell();
        } else {
          // User is not authenticated, show auth screen
          return const AuthScreen();
        }
      },
    );
  }
}
