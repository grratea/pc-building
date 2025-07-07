import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'configuration_provider.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green.shade900,
          brightness: Brightness.dark,
          surface: Colors.black,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade900,
          centerTitle: true,
          elevation: 4,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: CpuScreen(),
    ),
  );
}

class CpuScreen extends StatefulWidget {
  const CpuScreen({super.key});

  @override
  State<CpuScreen> createState() => _CpuScreenState();
}

class _CpuScreenState extends State<CpuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _cpusStream;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cpusStream = _firestore.collection('cpus').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select CPU',
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
                delegate: CpuSearchDelegate(_cpusStream),
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
                  hintText: 'Search CPUs...',
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
                stream: _cpusStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No CPUs found'));
                  }

                  // Filter and sort CPUs
                  var cpus = snapshot.data!.docs
                      .where((doc) => doc['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery))
                      .toList()
                    ..sort((a, b) {
                      // Safely get prices and convert to double
                      final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
                      final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;

                      if (priceA != priceB) return priceA.compareTo(priceB);
                      return a['name'].compareTo(b['name']);
                    });

                  return ListView.builder(
                    itemCount: cpus.length,
                    itemBuilder: (context, index) {
                      var cpu = cpus[index];
                      return _buildCpuCard(cpu);
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

  Widget _buildCpuCard(QueryDocumentSnapshot cpu) {
    // Safely convert price to double
    final price = (cpu['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.memory, color: Colors.white, size: 36),
        title: Text(
          cpu['name'] ?? 'Unnamed CPU',
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
            if (cpu['socket'] != null)
              Text(
                'Socket: ${cpu['socket']}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (cpu['cores'] != null)
              Text(
                'Cores: ${cpu['cores']}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (cpu['threads'] != null)
              Text(
                'Threads: ${cpu['threads']}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          print('Selected CPU: ${cpu['name']}');
          final socket = cpu['socket'] as String? ?? 'Unknown';
          Provider.of<ConfigurationProvider>(context, listen: false).setCpu(cpu.id, socket);
          Navigator.pushNamed(context, '/mobo');
        },
      ),
    );
  }
}

class CpuSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> cpusStream;

  CpuSearchDelegate(this.cpusStream);

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
      stream: cpusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          return doc['name'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final cpu = results[index];
            // Safely format price for search results
            final price = (cpu['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

            return ListTile(
              title: Text(cpu['name']),
              subtitle: Text(priceString),
              onTap: () {
                close(context, cpu);
              },
            );
          },
        );
      },
    );
  }
}