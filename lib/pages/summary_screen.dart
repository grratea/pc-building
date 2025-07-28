import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  double totalPrice = 0.0;
  bool isLoading = true;
  Map<String, Map<String, dynamic>> componentsAll = {};

  @override
  void initState() {
    super.initState();
    loadConfiguration();
  }

  Future<void> loadConfiguration() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final config = configProvider.currentConfig;

    final componentFutures = <Future>[];
    final components = <String, Map<String, dynamic>>{};

    // Define component types and their IDs
    final componentTypes = {
      'CPU': config.cpuId,
      'GPU': config.gpuId,
      'Motherboard': config.motherboardId,
      'RAM': config.ramId,
      'Storage': config.storageId,
      'PSU': config.psuId,
      'Case': config.caseId,
    };

    // Fetch all component data
    for (final entry in componentTypes.entries) {
      if (entry.value != null) {
        final future = firestore.collection(getCollectionName(entry.key))
            .doc(entry.value)
            .get()
            .then((doc) {
          if (doc.exists) {
            components[entry.key] = doc.data()!;
          }
        });
        componentFutures.add(future);
      }
    }
    // Wait for all fetches to complete
    await Future.wait(componentFutures);

    // Calculate total price
    double total = 0.0;
    components.forEach((_, data) {
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      total += price;
    });

    setState(() {
      componentsAll = components;
      totalPrice = total;
      isLoading = false;
    });
  }

  String getCollectionName(String componentType) {
    switch (componentType) {
      case 'CPU': return 'cpus';
      case 'GPU': return 'gpus';
      case 'Motherboard': return 'mobos';
      case 'RAM': return 'rams';
      case 'Storage': return 'storages';
      case 'PSU': return 'psus';
      case 'Case': return 'cases';
      default: return '';
    }
  }

  Widget buildComponentCard(String title, Map<String, dynamic>? data) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final priceString = '\$${price.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: getComponentIcon(title),
        title: Text(
          data['name'] ?? 'Unknown Component',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            if (title == 'CPU' && data['socket'] != null)
              Text('Socket: ${data['socket']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'GPU' && data['memory'] != null)
              Text('Memory: ${data['memory']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'RAM' && data['capacity'] != null)
              Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'Storage' && data['capacity'] != null)
              Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'PSU' && data['wattage'] != null)
              Text('Wattage: ${data['wattage']} W', style: const TextStyle(color: Colors.white70)),
            if (title == 'Case' && data['maxGpuLength'] != null)
              Text('Max GPU: ${data['maxGpuLength']} mm', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget getComponentIcon(String componentType) {
    switch (componentType) {
      case 'CPU': return const Icon(Icons.memory, color: Colors.white, size: 30);
      case 'GPU': return const Icon(Icons.videogame_asset, color: Colors.white, size: 30);
      case 'Motherboard': return const Icon(Icons.developer_board, color: Colors.white, size: 30);
      case 'RAM': return const Icon(Icons.memory, color: Colors.white, size: 30);
      case 'Storage': return const Icon(Icons.storage, color: Colors.white, size: 30);
      case 'PSU': return const Icon(Icons.power, color: Colors.white, size: 30);
      case 'Case': return const Icon(Icons.computer, color: Colors.white, size: 30);
      default: return const Icon(Icons.device_unknown, color: Colors.white, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuration Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade600.withAlpha(260),
              Colors.black,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Your PC Build',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...componentsAll.entries.map((entry) => buildComponentCard(entry.key, entry.value)).toList(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withAlpha(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Edit Configuration',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        // Implement purchase functionality
                      },
                      child: const Text(
                        'Complete Build',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

