import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class PsuScreen extends StatefulWidget {
  const PsuScreen({super.key});

  @override
  State<PsuScreen> createState() => _PsuScreenState();
}

class _PsuScreenState extends State<PsuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _psusStream;
  String _searchQuery = '';
  double _requiredPower = 0.0;

  @override
  void initState() {
    super.initState();
    _psusStream = _firestore.collection('psus').snapshots();
    _calculateRequiredPower();
  }

  Future<void> _calculateRequiredPower() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    double totalPower = 0.0;

    // Fetch CPU power
    if (configProvider.currentConfig.cpuId != null) {
      final cpuDoc = await _firestore.collection('cpus').doc(configProvider.currentConfig.cpuId).get();
      if (cpuDoc.exists) {
        totalPower += (cpuDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Fetch GPU power
    if (configProvider.currentConfig.gpuId != null) {
      final gpuDoc = await _firestore.collection('gpus').doc(configProvider.currentConfig.gpuId).get();
      if (gpuDoc.exists) {
        totalPower += (gpuDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }

    // Fetch RAM power (assuming 5W per stick)
    if (configProvider.currentConfig.ramId != null) {
      totalPower += 15.0;
    }

    // Fetch Storage power
    if (configProvider.currentConfig.storageId != null) {
      final storageDoc = await _firestore.collection('storages').doc(configProvider.currentConfig.storageId).get();
      if (storageDoc.exists) {
        totalPower += (storageDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }

    setState(() {
      _requiredPower = totalPower * 1.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Power Supply',
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
                delegate: PsuSearchDelegate(_psusStream, _requiredPower),
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
            // Power requirement banner
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.deepPurple.shade800,
              child: Column(
                children: [
                  Text(
                    'Required Power: ${_requiredPower.toStringAsFixed(0)}W',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Only PSUs with sufficient wattage are shown',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search PSUs...',
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
                stream: _psusStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No PSUs found'));
                  }

                  var psus = snapshot.data!.docs.where((doc) {
                    final power = (doc['power'] as num?)?.toDouble() ?? 0.0;
                    final name = doc['name'].toString().toLowerCase();

                    // Filter by power requirement and search query
                    return power >= _requiredPower &&
                        name.contains(_searchQuery);
                  }).toList()
                    ..sort((a, b) {
                      final powerA = (a['power'] as num?)?.toDouble() ?? 0.0;
                      final powerB = (b['power'] as num?)?.toDouble() ?? 0.0;
                      if (powerA != powerB) return powerA.compareTo(powerB);
                      return a['name'].toString().compareTo(b['name'].toString());
                    });

                  return ListView.builder(
                    itemCount: psus.length,
                    itemBuilder: (context, index) {
                      var psu = psus[index];
                      return _buildPsuCard(psu);
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

  Widget _buildPsuCard(QueryDocumentSnapshot psu) {
    final power = (psu['power'] as num?)?.toDouble() ?? 0.0;
    final price = (psu['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
    final efficiency = psu['efficiency'] as String? ?? 'N/A';
    final isSufficient = power >= _requiredPower;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.power, color: Colors.white, size: 36),
        title: Text(
          psu['name'] ?? 'Unknown PSU',
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
              '$power W • $efficiency',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Icon(
                //   isSufficient ? Icons.check_circle : Icons.warning,
                //   color: isSufficient ? Colors.green : Colors.orange,
                //   size: 16,
                // ),
                // const SizedBox(width: 4),
                // Text(
                //   isSufficient
                //       ? 'Sufficient for your build'
                //       : 'Insufficient power',
                //   style: TextStyle(
                //       color: isSufficient ? Colors.green : Colors.orange,
                //       fontWeight: FontWeight.bold
                //   ),
                // ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          if (isSufficient) {
            Provider.of<ConfigurationProvider>(context, listen: false)
                .setPsu(psu.id);
            Navigator.pushNamed(context, '/case');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$power W is insufficient for your build'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }
}

class PsuSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> psusStream;
  final double requiredPower;

  PsuSearchDelegate(this.psusStream, this.requiredPower);

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
      stream: psusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final power = (doc['power'] as num?)?.toDouble() ?? 0.0;
          final name = doc['name'].toString().toLowerCase();
          return power >= requiredPower && name.contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final psu = results[index];
            final power = (psu['power'] as num?)?.toDouble() ?? 0.0;
            final price = (psu['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

            return ListTile(
              title: Text(psu['name']),
              subtitle: Text('$power W • $priceString'),
              trailing: power >= requiredPower
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.warning, color: Colors.orange),
              onTap: () {
                close(context, psu);
              },
            );
          },
        );
      },
    );
  }
}
