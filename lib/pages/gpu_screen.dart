import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';


// class GpuScreen extends StatefulWidget {
//   const GpuScreen({super.key});
//
//   @override
//   State<GpuScreen> createState() => _GpuScreenState();
// }
//
// class _GpuScreenState extends State<GpuScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late Stream<QuerySnapshot> _gpusStream;
//   String _searchQuery = '';
//   double? _cpuPower;
//
//   @override
//   void initState() {
//     super.initState();
//     _gpusStream = _firestore.collection('gpus').snapshots();
//     _loadCpuPower();
//   }
//
//   Future<void> _loadCpuPower() async {
//     final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
//     final cpuId = configProvider.currentConfig.cpuId;
//
//     if (cpuId != null) {
//       final cpuDoc = await _firestore.collection('cpus').doc(cpuId).get();
//       if (cpuDoc.exists) {
//         final cpuData = cpuDoc.data() as Map<String, dynamic>;
//         setState(() {
//           _cpuPower = (cpuData['power'] as num?)?.toDouble();
//         });
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Select Graphics Card',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.black,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               // Search implementation (same as before)
//             },
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.green.shade900.withAlpha(204),
//               Colors.black,
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Bottleneck warning banner
//             if (_cpuPower != null)
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 color: Colors.orange.shade800,
//                 child: const Text(
//                   'Showing only GPUs compatible with your CPU (no bottleneck)',
//                   style: TextStyle(color: Colors.white, fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Search GPUs...',
//                   hintStyle: const TextStyle(color: Colors.white70),
//                   prefixIcon: const Icon(Icons.search, color: Colors.white70),
//                   filled: true,
//                   fillColor: Colors.green.shade900.withOpacity(0.3),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//                 style: const TextStyle(color: Colors.white),
//                 onChanged: (value) {
//                   setState(() {
//                     _searchQuery = value.toLowerCase();
//                   });
//                 },
//               ),
//             ),
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: _gpusStream,
//                 builder: (context, snapshot) {
//                   if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   }
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return const Center(child: Text('No GPUs found'));
//                   }
//
//                   // Filter and sort GPUs
//                   var gpus = snapshot.data!.docs
//                       .where((doc) => doc['name']
//                       .toString()
//                       .toLowerCase()
//                       .contains(_searchQuery))
//                       .toList()
//                     ..sort((a, b) {
//                       final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
//                       final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
//                       if (priceA != priceB) return priceA.compareTo(priceB);
//                       return a['name'].compareTo(b['name']);
//                     });
//
//                   // Apply bottleneck filter if CPU power is available
//                   var filteredGpus = gpus.where((gpu) {
//                     final gpuPower = (gpu['power'] as num?)?.toDouble();
//                     if (_cpuPower == null || gpuPower == null) return true;
//                     // Only show GPUs with power <= CPU power (no bottleneck)
//                     return gpuPower <= _cpuPower!;
//                   }).toList();
//
//                   return ListView.builder(
//                     itemCount: filteredGpus.length,
//                     itemBuilder: (context, index) {
//                       var gpu = filteredGpus[index];
//                       final gpuPower = (gpu['power'] as num?)?.toDouble();
//                       final isBottleneck = _cpuPower != null &&
//                           gpuPower != null &&
//                           gpuPower > _cpuPower!;
//
//                       return Card(
//                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                         color: Colors.green.shade900.withOpacity(0.5),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.all(16),
//                           leading: const Icon(Icons.videogame_asset, color: Colors.white, size: 36),
//                           title: Text(
//                             gpu['name'] ?? 'Unknown GPU',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 18,
//                             ),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const SizedBox(height: 8),
//                               Text(
//                                 '\$${(gpu['price'] as num?)?.toStringAsFixed(2) ?? 'Price N/A'}',
//                                 style: const TextStyle(color: Colors.white70, fontSize: 16),
//                               ),
//                               Text(
//                                 'Memory: ${gpu['memory'] ?? 'N/A'}',
//                                 style: const TextStyle(color: Colors.white70),
//                               ),
//                               // Show bottleneck warning if somehow a bottleneck GPU is shown
//                               if (isBottleneck)
//                                 Text(
//                                   'WARNING: Bottleneck with your CPU!',
//                                   style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//                                 ),
//                             ],
//                           ),
//                           trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
//                           onTap: () {
//                             print('Selected GPU: ${gpu['name']}');
//                             Provider.of<ConfigurationProvider>(context, listen: false)
//                                 .setGpu(gpu.id);
//                             // Navigate to next step (e.g., RAM, storage, or save)
//                             Navigator.pushNamed(context, '/ram');
//                           },
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class GpuScreen extends StatefulWidget {
  const GpuScreen({super.key});

  @override
  State<GpuScreen> createState() => _GpuScreenState();
}

class _GpuScreenState extends State<GpuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _gpusStream;
  String _searchQuery = '';
  double? _cpuPower;

  static const double minRatio = 0.8;
  static const double maxRatio = 1.2;

  @override
  void initState() {
    super.initState();
    _gpusStream = _firestore.collection('gpus').snapshots();
    _loadCpuPower();
  }

  Future<void> _loadCpuPower() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final cpuId = configProvider.currentConfig.cpuId;

    if (cpuId != null) {
      final cpuDoc = await _firestore.collection('cpus').doc(cpuId).get();
      if (cpuDoc.exists) {
        final cpuData = cpuDoc.data() as Map<String, dynamic>;
        setState(() {
          _cpuPower = (cpuData['power'] as num?)?.toDouble();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Graphics Card',
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
                delegate: GpuSearchDelegate(_gpusStream),
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
            if (_cpuPower != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange.shade800,
                  child: const Text(
                    'Showing GPUs compatible with your CPU',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search GPUs...',
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
                stream: _gpusStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No GPUs found'));
                  }

                  // Filter and sort GPUs
                  var gpus = snapshot.data!.docs
                      .where((doc) => doc['name']
                      .toString()
                      .toLowerCase()
                      .contains(_searchQuery))
                      .toList()
                    ..sort((a, b) {
                      final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
                      final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
                      if (priceA != priceB) return priceA.compareTo(priceB);
                      return a['name'].compareTo(b['name']);
                    });

                  // Apply balanced power filter
                  var filteredGpus = gpus.where((gpu) {
                    final gpuPower = (gpu['power'] as num?)?.toDouble();
                    if (_cpuPower == null || gpuPower == null) return true;

                    final ratio = gpuPower / _cpuPower!;
                    return ratio >= minRatio && ratio <= maxRatio;
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredGpus.length,
                    itemBuilder: (context, index) {
                      var gpu = filteredGpus[index];
                      final gpuPower = (gpu['power'] as num?)?.toDouble();
                      final ratio = _cpuPower != null && gpuPower != null
                          ? gpuPower / _cpuPower!
                          : null;

                      return _buildGpuCard(gpu, ratio);
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

  Widget _buildGpuCard(QueryDocumentSnapshot gpu, double? ratio) {
    final gpuPower = (gpu['power'] as num?)?.toDouble();
    final String status;
    final Color statusColor;

    // if (ratio == null) {
    //   status = "Power data unavailable";
    //   statusColor = Colors.grey;
    // } else if (ratio >= minRatio && ratio <= maxRatio) {
    //   status = "Balanced configuration ✅";
    //   statusColor = Colors.green;
    // } else if (ratio > maxRatio) {
    //   status = "CPU bottleneck warning ⚠️";
    //   statusColor = Colors.orange;
    // } else {
    //   status = "GPU bottleneck warning ⚠️";
    //   statusColor = Colors.orange;
    // }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.videogame_asset, color: Colors.white, size: 36),
        title: Text(
          gpu['name'] ?? 'Unknown GPU',
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
              '\$${(gpu['price'] as num?)?.toStringAsFixed(2) ?? 'Price N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Memory: ${gpu['memory'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Icon(Icons.info_outline, color: statusColor, size: 16),
                // const SizedBox(width: 4),
                // Text(
                //   status,
                //   style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                // ),
              ],
            ),
            if (ratio != null) ...[
              const SizedBox(height: 4),
              // LinearProgressIndicator(
              //   value: ratio.clamp(0, 2) / 2,
              //   backgroundColor: Colors.grey[800],
              //   valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              // ),
              Text(
                'CPU/GPU Ratio: ${ratio.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ]
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          if (ratio == null || (ratio >= minRatio && ratio <= maxRatio)) {
            Provider.of<ConfigurationProvider>(context, listen: false)
                .setGpu(gpu.id);
            Navigator.pushNamed(context, '/ram');
          // } else {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Bottleneck warning! $status'),
          //       backgroundColor: Colors.orange,
          //     ),
          //   );
          }
        },
      ),
    );
  }
}

class GpuSearchDelegate extends SearchDelegate {
  final Stream<QuerySnapshot> gpusStream;

  GpuSearchDelegate(this.gpusStream);

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
      stream: gpusStream,
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
            final gpu = results[index];
            final price = (gpu['price'] as num?)?.toDouble();
            final priceString = price != null ? '\$${price.toStringAsFixed(2)}' : 'Price N/A';

            return ListTile(
              title: Text(gpu['name']),
              subtitle: Text(priceString),
              onTap: () {
                close(context, gpu);
              },
            );
          },
        );
      },
    );
  }
}

