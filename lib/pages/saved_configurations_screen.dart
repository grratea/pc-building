import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedConfigurationsScreen extends StatelessWidget {
  const SavedConfigurationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Saved Configurations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore.collection('configurations').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No saved configurations found.',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              );
            }

            final configs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: configs.length,
              itemBuilder: (context, index) {
                final config = configs[index];
                final configName = config['name'] ?? 'Unnamed Configuration';

                return Card(
                  color: Colors.green.shade900.withAlpha(70),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    title: Text(
                      configName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    trailing:
                    const Icon(Icons.keyboard_arrow_right, color: Colors.white70),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SummaryScreenWithConfig(id: config.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class SummaryScreenWithConfig extends StatefulWidget {
  final String id;
  const SummaryScreenWithConfig({required this.id, super.key});

  @override
  State<SummaryScreenWithConfig> createState() => _SummaryScreenWithConfigState();
}

class _SummaryScreenWithConfigState extends State<SummaryScreenWithConfig> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> componentsAll = {};
  double totalPrice = 0.0;
  bool isLoading = true;

  String? configName;
  String? configDescription;
  String? configUser;
  String? configUserUsername;

  @override
  void initState() {
    super.initState();
    loadSavedConfiguration();
  }

  Future<void> loadSavedConfiguration() async {
    final configDoc = await firestore.collection('configurations').doc(widget.id).get();

    if (!configDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration not found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final config = configDoc.data()!;
    configName = config['name'] as String? ?? 'Unnamed Build';
    configDescription = config['description'] as String? ?? '';
    configUser = config['userId'] as String? ?? '';

    // Fetch user's username from users collection
    if (configUser != null && configUser!.isNotEmpty) {
      final userDoc = await firestore.collection('users').doc(configUser).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        configUserUsername = userData?['username'] as String?;
      }
    }

    final componentTypes = {
      'CPU': config['cpu'] as String?,
      'GPU': config['gpu'] as String?,
      'Motherboard': config['mobo'] as String?,
      'RAM': config['ram'] as String?,
      'Storage': config['storage'] as String?,
      'PSU': config['psu'] as String?,
      'Case': config['case'] as String?,
    };

    final components = <String, Map<String, dynamic>>{};
    final futures = <Future>[];

    for (final entry in componentTypes.entries) {
      if (entry.value != null) {
        final f = firestore.collection(_getCollectionName(entry.key))
            .doc(entry.value!)
            .get()
            .then((doc) {
          if (doc.exists) {
            components[entry.key] = doc.data()!;
          }
        });
        futures.add(f);
      }
    }

    await Future.wait(futures);

    double total = 0.0;
    components.forEach((_, data) {
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      total += price;
    });

    if (mounted) {
      setState(() {
        componentsAll = components;
        totalPrice = total;
        isLoading = false;
      });
    }
  }

  String _getCollectionName(String type) {
    switch (type) {
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
    if (data == null) return const SizedBox.shrink();

    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final priceString = '\$${price.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withAlpha(107),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getComponentIcon(title),
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
            Text(priceString, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            if (title == 'CPU' && data['socket'] != null) Text('Socket: ${data['socket']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'GPU' && data['memory'] != null) Text('Memory: ${data['memory']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'RAM' && data['capacity'] != null) Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'Storage' && data['capacity'] != null) Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'PSU' && data['wattage'] != null) Text('Wattage: ${data['wattage']} W', style: const TextStyle(color: Colors.white70)),
            if (title == 'Case' && data['maxGpuLength'] != null) Text('Max GPU: ${data['maxGpuLength']} mm', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _getComponentIcon(String componentType) {
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
          'Saved Configuration Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
                padding: const EdgeInsets.all(16),
                children: [
                  if (configName != null)
                    Text(
                      configName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  if (configDescription != null && configDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        configDescription!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  if (configUserUsername != null && configUserUsername!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Created by: $configUserUsername',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ...componentsAll.entries.map((entry) => buildComponentCard(entry.key, entry.value)),
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
                        'Back',
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



/*class SummaryScreenWithConfig extends StatefulWidget {
  final String id;
  const SummaryScreenWithConfig({required this.id, super.key});

  @override
  State<SummaryScreenWithConfig> createState() => _SummaryScreenWithConfigState();
}

class _SummaryScreenWithConfigState extends State<SummaryScreenWithConfig> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> componentsAll = {};
  double totalPrice = 0.0;
  bool isLoading = true;

  String? configName;
  String? configDescription;
  String? configUser;

  @override
  void initState() {
    super.initState();
    loadSavedConfiguration();
  }

  Future<void> loadSavedConfiguration() async {
    final configDoc = await firestore.collection('configurations').doc(widget.id).get();

    if (!configDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration not found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    final config = configDoc.data()!;
    configName = config['name'] as String? ?? 'Unnamed Build';
    configDescription = config['description'] as String? ?? '';
    configUser = config['userId'] as String? ?? '';

    final componentTypes = {
      'CPU': config['cpu'] as String?,
      'GPU': config['gpu'] as String?,
      'Motherboard': config['mobo'] as String?,
      'RAM': config['ram'] as String?,
      'Storage': config['storage'] as String?,
      'PSU': config['psu'] as String?,
      'Case': config['case'] as String?,
    };

    final components = <String, Map<String, dynamic>>{};
    final futures = <Future>[];

    for (final entry in componentTypes.entries) {
      if (entry.value != null) {
        final f = firestore.collection(_getCollectionName(entry.key))
            .doc(entry.value!)
            .get()
            .then((doc) {
          if (doc.exists) {
            components[entry.key] = doc.data()!;
          }
        });
        futures.add(f);
      }
    }

    await Future.wait(futures);

    double total = 0.0;
    components.forEach((_, data) {
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      total += price;
    });

    if (mounted) {
      setState(() {
        componentsAll = components;
        totalPrice = total;
        isLoading = false;
      });
    }
  }

  String _getCollectionName(String type) {
    switch (type) {
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
    if (data == null) return const SizedBox.shrink();

    final price = (data['price'] as num?)?.toDouble() ?? 0.0;
    final priceString = '\$${price.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green.shade900.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _getComponentIcon(title),
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
            Text(priceString, style: const TextStyle(color: Colors.white70, fontSize: 15)),
            if (title == 'CPU' && data['socket'] != null) Text('Socket: ${data['socket']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'GPU' && data['memory'] != null) Text('Memory: ${data['memory']}', style: const TextStyle(color: Colors.white70)),
            if (title == 'RAM' && data['capacity'] != null) Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'Storage' && data['capacity'] != null) Text('Capacity: ${data['capacity']} GB', style: const TextStyle(color: Colors.white70)),
            if (title == 'PSU' && data['wattage'] != null) Text('Wattage: ${data['wattage']} W', style: const TextStyle(color: Colors.white70)),
            if (title == 'Case' && data['maxGpuLength'] != null) Text('Max GPU: ${data['maxGpuLength']} mm', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _getComponentIcon(String componentType) {
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
          'Saved Configuration Summary',
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
                padding: const EdgeInsets.all(16),
                children: [
                  if (configName != null)
                    Text(
                      configName!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  if (configDescription != null && configDescription!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                      child: Text(
                        configDescription!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  if (configUser != null && configUser!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Created by: $configUser',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),

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
                        'Back',
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
}*/


