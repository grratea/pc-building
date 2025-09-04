import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';


class SavedConfigurationsScreen extends StatelessWidget {
  const SavedConfigurationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
        body: const Center(
          child: Text(
            'Please log in to see your configurations',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

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
            colors: [Colors.green.shade600.withAlpha(260), Colors.black],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('configurations')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red[900],
                            size: 25,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Configuration'),
                                content: const Text(
                                  'Are you sure you want to delete this configuration?',
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text('Delete'),
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await firestore
                                  .collection('configurations')
                                  .doc(config.id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configuration deleted'),
                                ),
                              );
                            }
                          },
                        ),
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
                                    SummaryScreenWithConfig(id: config.id),
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


class SummaryScreenWithConfig extends StatefulWidget {
  final String id;

  const SummaryScreenWithConfig({required this.id, super.key});

  @override
  State<SummaryScreenWithConfig> createState() =>
      _SummaryScreenWithConfigState();
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

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isSaving = false;

  bool isPublic = false;

  @override
  void initState() {
    super.initState();
    loadSavedConfiguration();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
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
    isPublic = config['isPublic'] as bool? ?? false; // load privacy status

    nameController.text = configName!;
    descriptionController.text = configDescription!;

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

  Future<void> updateConfiguration() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final configId = widget.id;

    final data = configProvider.currentConfig.toMap();
    data['name'] = nameController.text.trim();
    data['description'] = descriptionController.text.trim();
    data['userId'] = FirebaseAuth.instance.currentUser?.uid ?? '';
    data['savedAt'] = FieldValue.serverTimestamp();
    data['isPublic'] = isPublic;

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
      setState(() => isSaving = false);
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
                key: formKey,
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
                          SwitchListTile(
                            title: const Text(
                              'Make configuration public',
                              style: TextStyle(color: Colors.white),
                            ),
                            value: isPublic,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() {
                                isPublic = value;
                              });
                            },
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
                          ElevatedButton(
                            onPressed: isSaving ? null : updateConfiguration,
                            child: isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save'),
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
