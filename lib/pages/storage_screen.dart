import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _storagesStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _storagesStream = _firestore.collection('storages').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Storage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: StorageSearchDelegate(_storagesStream),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade900.withAlpha(204),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Storage...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.green.shade900.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _storagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No storage devices found'));
                  }

                  var storages = snapshot.data!.docs
                      .where((doc) => doc['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery))
                      .toList()
                    ..sort((a, b) {
                      final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
                      final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
                      if (priceA != priceB) return priceA.compareTo(priceB);
                      return a['name'].toString().compareTo(b['name'].toString());
                    });

                  return ListView.builder(
                    itemCount: storages.length,
                    itemBuilder: (context, index) {
                      var storage = storages[index];
                      return _buildStorageCard(storage);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(QueryDocumentSnapshot storage) {
    final price = (storage['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
    final capacity = storage['capacity'] as String? ?? 'N/A';
    final type = storage['type'] as String? ?? 'N/A';
    final speed = storage['speed'] as String? ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.storage, color: Colors.white, size: 36),
        title: Text(
          storage['name'] ?? 'Unknown Storage',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Capacity: $capacity',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Type: $type',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Speed: $speed',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          Provider.of<ConfigurationProvider>(context, listen: false)
              .setStorage(storage.id);
          Navigator.pushNamed(context, '/psu'); // Or next step
        },
      ),
    );
  }
}

class StorageSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> storagesStream;

  StorageSearchDelegate(this.storagesStream);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: storagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final name = doc['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final storage = results[index];
            final price = (storage['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
            return ListTile(
              title: Text(storage['name']),
              subtitle: Text(priceString),
              onTap: () {
                close(context, storage);
              },
            );
          },
        );
      },
    );
  }
}
