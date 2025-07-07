import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({super.key});

  @override
  State<CaseScreen> createState() => _CaseScreenState();
}

class _CaseScreenState extends State<CaseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _casesStream;
  String _searchQuery = '';
  double? _gpuLength;

  @override
  void initState() {
    super.initState();
    _casesStream = _firestore.collection('cases').snapshots();
    _loadGpuLength();
  }

  Future<void> _loadGpuLength() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final gpuId = configProvider.currentConfig.gpuId;

    if (gpuId != null) {
      final gpuDoc = await _firestore.collection('gpus').doc(gpuId).get();
      if (gpuDoc.exists) {
        final gpuData = gpuDoc.data() as Map<String, dynamic>;
        setState(() {
          _gpuLength = (gpuData['length'] as num?)?.toDouble();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Case',
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
                delegate: CaseSearchDelegate(_casesStream, _gpuLength),
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
            // GPU/case compatibility banner
            if (_gpuLength != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade800,
                child: Column(
                  children: [
                    Text(
                      'Your GPU length: ${_gpuLength!.toStringAsFixed(0)} mm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Only cases that fit your GPU are shown',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Cases...',
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
                stream: _casesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No cases found'));
                  }

                  var cases = snapshot.data!.docs.where((doc) {
                    final maxGpuLength = (doc['maxGpuLength'] as num?)?.toDouble();
                    final name = doc['name'].toString().toLowerCase();

                    // Show all cases if GPU length is not set
                    if (_gpuLength == null) return true;

                    // Filter by GPU length and search query
                    return maxGpuLength != null &&
                        maxGpuLength >= _gpuLength! &&
                        name.contains(_searchQuery);
                  }).toList()
                    ..sort((a, b) {
                      final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
                      final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
                      if (priceA != priceB) return priceA.compareTo(priceB);
                      return a['name'].toString().compareTo(b['name'].toString());
                    });

                  return ListView.builder(
                    itemCount: cases.length,
                    itemBuilder: (context, index) {
                      var pcCase = cases[index];
                      return _buildCaseCard(pcCase, _gpuLength);
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

  Widget _buildCaseCard(QueryDocumentSnapshot pcCase, double? gpuLength) {
    final maxGpuLength = (pcCase['maxGpuLength'] as num?)?.toDouble();
    final price = (pcCase['price'] as num?)?.toDouble();
    final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
    final canFitGpu = gpuLength == null || maxGpuLength == null || maxGpuLength >= gpuLength;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.computer, color: Colors.white, size: 36),
        title: Text(
          pcCase['name'] ?? 'Unknown Case',
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
              'Max GPU Length: ${maxGpuLength?.toStringAsFixed(0) ?? 'N/A'} mm',
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
                //   canFitGpu ? Icons.check_circle : Icons.warning,
                //   color: canFitGpu ? Colors.green : Colors.orange,
                //   size: 16,
                // ),
                // const SizedBox(width: 4),
                // Text(
                //   canFitGpu
                //       ? (gpuLength == null
                //       ? 'GPU not selected'
                //       : 'Fits your GPU')
                //       : 'GPU too long',
                //   style: TextStyle(
                //     color: canFitGpu ? Colors.green : Colors.orange,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          if (gpuLength == null || canFitGpu) {
            Provider.of<ConfigurationProvider>(context, listen: false)
                .setCase(pcCase.id);
            Navigator.pushNamed(context, '/summary');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Case does not fit your GPU'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }
}

class CaseSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> casesStream;
  final double? gpuLength;

  CaseSearchDelegate(this.casesStream, this.gpuLength);

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
      stream: casesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final maxGpuLength = (doc['maxGpuLength'] as num?)?.toDouble();
          final name = doc['name'].toString().toLowerCase();

          if (gpuLength == null) return true;
          return maxGpuLength != null &&
              maxGpuLength >= gpuLength! &&
              name.contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final pcCase = results[index];
            final maxGpuLength = (pcCase['maxGpuLength'] as num?)?.toDouble();
            final price = (pcCase['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';
            final canFitGpu = gpuLength == null || maxGpuLength == null || maxGpuLength >= gpuLength!;

            return ListTile(
              title: Text(pcCase['name']),
              subtitle: Text('Max GPU: ${maxGpuLength?.toStringAsFixed(0) ?? 'N/A'} mm • $priceString'),
              trailing: canFitGpu
                  ? const Icon(Icons.check, color: Colors.green)
                  : const Icon(Icons.warning, color: Colors.orange),
              onTap: () {
                close(context, pcCase);
              },
            );
          },
        );
      },
    );
  }
}
