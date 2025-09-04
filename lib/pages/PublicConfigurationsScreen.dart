import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'configuration_provider.dart';


class PublicConfigurationsScreen extends StatelessWidget {
  const PublicConfigurationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Public Configurations',
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
          stream: firestore
              .collection('configurations')
              .where('isPublic', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No public configurations found.',
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.keyboard_arrow_right,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PublicSummaryScreen(id: config.id),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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


class PublicSummaryScreen extends StatefulWidget {
  final String id;

  const PublicSummaryScreen({required this.id, super.key});

  @override
  State<PublicSummaryScreen> createState() =>
      _SummaryScreenWithConfigState();
}

class _SummaryScreenWithConfigState extends State<PublicSummaryScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Map<String, Map<String, dynamic>> componentsAll = {};
  double totalPrice = 0.0;
  bool isLoading = true;

  String? configName;
  String? configDescription;
  String? configUser;
  String? configUserUsername;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    loadSavedConfiguration();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadSavedConfiguration() async {
    final configDoc = await firestore
        .collection('configurations')
        .doc(widget.id)
        .get();

    if (!configDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration not found')),
        );
        Navigator.pop(context);
      }
      return;
    }

    setState(() {
      isLoading = true;
      componentsAll = {};
      totalPrice = 0;
    });

    final config = configDoc.data()!;
    configName = config['name'] as String? ?? 'Unnamed Build';
    configDescription = config['description'] as String? ?? '';
    configUser = config['userId'] as String? ?? '';
    _isPublic = config['isPublic'] as bool? ?? false;

    _nameController.text = configName!;
    _descriptionController.text = configDescription!;

    if (configUser != null && configUser!.isNotEmpty) {
      final userDoc = await firestore.collection('users').doc(configUser).get();
      if (userDoc.exists) {
        configUserUsername = userDoc.data()?['username'] as String?;
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
        final f = firestore
            .collection(_getCollectionName(entry.key))
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
      case 'CPU':
        return 'cpus';
      case 'GPU':
        return 'gpus';
      case 'Motherboard':
        return 'mobos';
      case 'RAM':
        return 'rams';
      case 'Storage':
        return 'storages';
      case 'PSU':
        return 'psus';
      case 'Case':
        return 'cases';
      default:
        return '';
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
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            if (title == 'CPU' && data['socket'] != null)
              Text(
                'Socket: ${data['socket']}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (title == 'GPU' && data['memory'] != null)
              Text(
                'Memory: ${data['memory']}',
                style: const TextStyle(color: Colors.white70),
              ),
            if (title == 'RAM' && data['capacity'] != null)
              Text(
                'Capacity: ${data['capacity']} GB',
                style: const TextStyle(color: Colors.white70),
              ),
            if (title == 'Storage' && data['capacity'] != null)
              Text(
                'Capacity: ${data['capacity']} GB',
                style: const TextStyle(color: Colors.white70),
              ),
            if (title == 'PSU' && data['wattage'] != null)
              Text(
                'Wattage: ${data['wattage']} W',
                style: const TextStyle(color: Colors.white70),
              ),
            if (title == 'Case' && data['maxGpuLength'] != null)
              Text(
                'Max GPU: ${data['maxGpuLength']} mm',
                style: const TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getComponentIcon(String componentType) {
    switch (componentType) {
      case 'CPU':
        return const Icon(Icons.memory, color: Colors.white, size: 30);
      case 'GPU':
        return const Icon(Icons.videogame_asset, color: Colors.white, size: 30);
      case 'Motherboard':
        return const Icon(Icons.developer_board, color: Colors.white, size: 30);
      case 'RAM':
        return const Icon(Icons.memory, color: Colors.white, size: 30);
      case 'Storage':
        return const Icon(Icons.storage, color: Colors.white, size: 30);
      case 'PSU':
        return const Icon(Icons.power, color: Colors.white, size: 30);
      case 'Case':
        return const Icon(Icons.computer, color: Colors.white, size: 30);
      default:
        return const Icon(Icons.device_unknown, color: Colors.white, size: 30);
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final configId = widget.id;

    final data = configProvider.currentConfig.toMap();
    data['name'] = _nameController.text.trim();
    data['description'] = _descriptionController.text.trim();
    data['userId'] = FirebaseAuth.instance.currentUser?.uid ?? '';
    data['savedAt'] = FieldValue.serverTimestamp();
    data['isPublic'] = _isPublic;

    try {
      await firestore.collection('configurations').doc(configId).set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration updated successfully!')),
      );

      await loadSavedConfiguration();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuration Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade600.withAlpha(260), Colors.black],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
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
                    if (configDescription != null &&
                        configDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          configDescription!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    if (configUserUsername != null &&
                        configUserUsername!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Created by: $configUserUsername',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ...componentsAll.entries.map(
                          (entry) =>
                          buildComponentCard(entry.key, entry.value),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withAlpha(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Price: \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
