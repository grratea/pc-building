import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class RamScreen extends StatefulWidget {
  const RamScreen({super.key});

  @override
  State<RamScreen> createState() => _RamScreenState();
}

class _RamScreenState extends State<RamScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _ramsStream;
  String _searchQuery = '';
  String? _moboDdrType;

  @override
  void initState() {
    super.initState();
    _ramsStream = _firestore.collection('rams').snapshots();
    _loadMoboDdrType();
  }

  Future<void> _loadMoboDdrType() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final moboId = configProvider.currentConfig.motherboardId;

    if (moboId != null) {
      final moboDoc = await _firestore.collection('mobos').doc(moboId).get();
      if (moboDoc.exists) {
        final moboData = moboDoc.data() as Map<String, dynamic>;
        setState(() {
          _moboDdrType = (moboData['ddrType'] as String?)?.toUpperCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select RAM',
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
                delegate: RamSearchDelegate(_ramsStream, _moboDdrType),
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
            if (_moboDdrType != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade800,
                  child: Text(
                    'Showing RAM compatible with $_moboDdrType',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search RAM...',
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
                stream: _ramsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No RAM found'));
                  }

                  var rams = snapshot.data!.docs.where((doc) {
                    final ramDdr = (doc['ddrType'] as String?)?.toUpperCase();
                    final name = (doc['name'] as String?)?.toLowerCase() ?? '';

                    // Filter by DDR compatibility and search query
                    final ddrCompatible = _moboDdrType == null || ramDdr == _moboDdrType;
                    final matchesSearch = name.contains(_searchQuery);

                    return ddrCompatible && matchesSearch;
                  }).toList()
                    ..sort((a, b) {
                      final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
                      final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
                      if (priceA != priceB) return priceA.compareTo(priceB);
                      return a['name'].toString().compareTo(b['name'].toString());
                    });

                  return ListView.builder(
                    itemCount: rams.length,
                    itemBuilder: (context, index) {
                      var ram = rams[index];
                      return _buildRamCard(ram);
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

  Widget _buildRamCard(QueryDocumentSnapshot ram) {
    final price = (ram['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
    final capacity = ram['capacity'] as String? ?? 'N/A';
    final speed = ram['speed'] as String? ?? 'N/A';
    final ddrType = (ram['ddrType'] as String?)?.toUpperCase() ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.memory, color: Colors.white, size: 36),
        title: Text(
          ram['name'] ?? 'Unknown RAM',
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
              'Speed: $speed',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Type: $ddrType',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          Provider.of<ConfigurationProvider>(context, listen: false).setRam(ram.id);
          Navigator.pushNamed(context, '/storage');
        },
      ),
    );
  }
}

class RamSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> ramsStream;
  final String? moboDdrType;

  RamSearchDelegate(this.ramsStream, this.moboDdrType);

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
      stream: ramsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final ramDdr = (doc['ddrType'] as String?)?.toUpperCase();
          final name = (doc['name'] as String?)?.toLowerCase() ?? '';

          // Apply DDR compatibility filter
          final ddrCompatible = moboDdrType == null || ramDdr == moboDdrType;
          final matchesSearch = name.contains(query.toLowerCase());

          return ddrCompatible && matchesSearch;
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final ram = results[index];
            final price = (ram['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
            return ListTile(
              title: Text(ram['name']),
              subtitle: Text(priceString),
              onTap: () {
                close(context, ram);
              },
            );
          },
        );
      },
    );
  }
}
