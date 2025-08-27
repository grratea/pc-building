import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          username = doc.data()?['username'] ?? 'User';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Build My PC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              // Optionally navigate to login screen here
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Colors.green.shade600.withAlpha(260),
              Colors.black,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              Icon(
                Icons.computer_outlined,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 20),

              if (username != null)
                Text(
                  'Hi, $username!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 20),

              Text(
                'Welcome to Build My PC!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              Text(
                'Build your ideal computer configuration with compatibility checks and up-to-date prices.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Divider(
                height: 55,
                color: Colors.white,
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 20,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.black.withAlpha(60),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      FilledButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/cpu');
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(55),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.green.shade900,
                        ),
                        child: const Text(
                          'New Configuration',
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/saved_configurations');
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green.shade900.withAlpha(150),
                          foregroundColor: Colors.grey[200],
                        ),
                        child: const Text(
                          'My Saved Configurations',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () {
                          // Navigator.pushNamed(context, '/public_configurations');
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green.shade900.withAlpha(150),
                          foregroundColor: Colors.grey[200],
                        ),
                        child: const Text(
                          'Public Configurations',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      /*FilledButton(
                        onPressed: () {
                          // Navigate to component database
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.green.shade900.withAlpha(150),
                          foregroundColor: Colors.grey[200],
                        ),
                        child: const Text(
                          'Comparison Tool',
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                        ),
                      ),*/
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
