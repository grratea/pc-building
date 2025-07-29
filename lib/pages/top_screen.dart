import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopScreenWithSearch extends StatefulWidget {
  final String title;
  final String hintText;
  final Stream<QuerySnapshot> stream;
  final Widget Function(BuildContext, QuerySnapshot, String, bool) builder;
  final List<Widget>? actions;

  const TopScreenWithSearch({
    super.key,
    required this.title,
    required this.hintText,
    required this.stream,
    required this.builder,
    this.actions,
  });

  @override
  State<TopScreenWithSearch> createState() => _TopScreenWithSearchState();
}

class _TopScreenWithSearchState extends State<TopScreenWithSearch> {
  String searchQuery = '';
  bool sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
            ),
            tooltip: sortAscending
                ? 'Sort by price descending'
                : 'Sort by price ascending',
            onPressed: () {
              setState(() {
                sortAscending = !sortAscending;
              });
            },
          ),
          ...?widget.actions,
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade600.withAlpha(260), Colors.black],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.green.shade900.withAlpha(120),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: widget.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No items found'));
                  }
                  return widget.builder(context, snapshot.data!, searchQuery, sortAscending);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

