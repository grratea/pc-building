import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class MoboScreen extends StatefulWidget {
  const MoboScreen({super.key});

  @override
  State<MoboScreen> createState() => _MoboScreenState();
}

class _MoboScreenState extends State<MoboScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _mobosStream;
  String _searchQuery = '';

  // @override
  // void initState() {
  //   super.initState();
  //   _mobosStream = _firestore.collection('mobos').snapshots();
  // }

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final socket = configProvider.cpuSocket;

    if (socket != null) {
      _mobosStream = _firestore.collection('mobos')
          .where('socket', isEqualTo: socket)
          .snapshots();
    } else {
      _mobosStream = _firestore.collection('mobos').snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final cpuSocket = configProvider.cpuSocket;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Motherboard',
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
                delegate: MoboSearchDelegate(_mobosStream),
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
            if (cpuSocket != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade800,
                  child: Text(
                    'Showing motherboards for $cpuSocket socket',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Motherboards...',
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
                stream: _mobosStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No motherboards found'));
                  }

                  // Filter and sort motherboards
                  var mobos = snapshot.data!.docs
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
                    itemCount: mobos.length,
                    itemBuilder: (context, index) {
                      var mobo = mobos[index];
                      return _buildMoboCard(mobo);
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

  Widget _buildMoboCard(QueryDocumentSnapshot mobo) {
    // Safely convert price to double
    final price = (mobo['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.build_sharp, color: Colors.white, size: 36),
        title: Text(
          mobo['name'] ?? 'Unnamed Motherboard',
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
            if (mobo['socket'] != null)
              Text(
                'Socket: ${mobo['socket']}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (mobo['ramSlots'] != null)
              Text(
                'RAM Slots: ${mobo['ramSlots']}',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          print('Selected Motherboard: ${mobo['name']}');
          Provider.of<ConfigurationProvider>(context, listen: false)
              .setMotherboard(mobo.id);
          Navigator.pushNamed(context, '/gpu');
        },
      ),
    );
  }
}

class MoboSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> mobosStream;

  MoboSearchDelegate(this.mobosStream);

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
      stream: mobosStream,
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
            final mobo = results[index];
            // Safely format price for search results
            final price = (mobo['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

            return ListTile(
              title: Text(mobo['name']),
              subtitle: Text(priceString),
              onTap: () {
                close(context, mobo);
              },
            );
          },
        );
      },
    );
  }
}
