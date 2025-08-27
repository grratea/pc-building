
/*
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';
import 'configuration.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  double totalPrice = 0.0;
  bool isLoading = true;
  bool _isPublic = false;

  String? configName;
  String? configDescription;
  String? configUser;
  Map<String, Map<String, dynamic>> componentsAll = {};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    loadConfiguration();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadConfiguration() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final Configuration config = configProvider.currentConfig;

    String? configId = configProvider.currentConfigId;
    if (configId == null) {
      await _loadComponentsFromCurrentConfig(config);
      return;
    }

    final configDoc = await firestore.collection('configurations').doc(configId).get();
    if (!configDoc.exists) {
      await _loadComponentsFromCurrentConfig(config);
      return;
    }

    final configData = configDoc.data()!;
    configName = configData['name'] as String? ?? 'Unnamed Build';
    configDescription = configData['description'] as String? ?? '';
    configUser = configData['userId'] as String? ?? '';

    _nameController.text = configName!;
    _descriptionController.text = configDescription!;

    final componentTypes = {
      'CPU': configData['cpu'] as String? ?? config.cpuId,
      'GPU': configData['gpu'] as String? ?? config.gpuId,
      'Motherboard': configData['mobo'] as String? ?? config.motherboardId,
      'RAM': configData['ram'] as String? ?? config.ramId,
      'Storage': configData['storage'] as String? ?? config.storageId,
      'PSU': configData['psu'] as String? ?? config.psuId,
      'Case': configData['case'] as String? ?? config.caseId,
    };

    await _loadComponents(componentTypes);
  }

  Future<void> _loadComponentsFromCurrentConfig(Configuration config) async {
    final componentTypes = {
      'CPU': config.cpuId,
      'GPU': config.gpuId,
      'Motherboard': config.motherboardId,
      'RAM': config.ramId,
      'Storage': config.storageId,
      'PSU': config.psuId,
      'Case': config.caseId,
    };
    await _loadComponents(componentTypes);
  }

  Future<void> _loadComponents(Map<String, String?> componentTypes) async {
    final components = <String, Map<String, dynamic>>{};
    final componentFutures = <Future>[];

    for (final entry in componentTypes.entries) {
      if (entry.value != null) {
        final future = firestore.collection(getCollectionName(entry.key)).doc(entry.value).get().then((doc) {
          if (doc.exists) {
            components[entry.key] = doc.data()!;
          }
        });
        componentFutures.add(future);
      }
    }

    await Future.wait(componentFutures);

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(priceString, style: const TextStyle(color: Colors.white70, fontSize: 15)),
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

    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);

    final data = configProvider.currentConfig.toMap();
    data['name'] = _nameController.text.trim();
    data['description'] = _descriptionController.text.trim();
    data['userId'] = FirebaseAuth.instance.currentUser?.uid ?? ''; // ensure userId included
    data['savedAt'] = FieldValue.serverTimestamp();

    try {
      if (configProvider.currentConfigId == null) {
        final docRef = await firestore.collection('configurations').add(data);
        configProvider.currentConfigId = docRef.id;
      } else {
        await firestore.collection('configurations').doc(configProvider.currentConfigId).set(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully!')),
      );

      // Navigate to home screen after save success:
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
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
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Configuration Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter configuration name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
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
                      style:
                      TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 24, fontWeight: FontWeight.bold),
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
                        onPressed: _isSaving ? null : _saveConfiguration,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text(
                          'Save Configuration',
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
      ),
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';
import 'configuration.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => SummaryScreenState();
}

class SummaryScreenState extends State<SummaryScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  double totalPrice = 0.0;
  bool isLoading = true;
  bool _isPublic = false;

  String? configName;
  String? configDescription;
  String? configUser;
  Map<String, Map<String, dynamic>> componentsAll = {};

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    loadConfiguration();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadConfiguration() async {
    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);
    final Configuration config = configProvider.currentConfig;

    String? configId = configProvider.currentConfigId;
    if (configId == null) {
      await _loadComponentsFromCurrentConfig(config);
      return;
    }

    final configDoc = await firestore.collection('configurations').doc(configId).get();
    if (!configDoc.exists) {
      await _loadComponentsFromCurrentConfig(config);
      return;
    }

    final configData = configDoc.data()!;
    configName = configData['name'] as String? ?? 'Unnamed Build';
    configDescription = configData['description'] as String? ?? '';
    configUser = configData['userId'] as String? ?? '';
    _isPublic = configData['isPublic'] as bool? ?? false;

    _nameController.text = configName!;
    _descriptionController.text = configDescription!;

    final componentTypes = {
      'CPU': configData['cpu'] as String? ?? config.cpuId,
      'GPU': configData['gpu'] as String? ?? config.gpuId,
      'Motherboard': configData['mobo'] as String? ?? config.motherboardId,
      'RAM': configData['ram'] as String? ?? config.ramId,
      'Storage': configData['storage'] as String? ?? config.storageId,
      'PSU': configData['psu'] as String? ?? config.psuId,
      'Case': configData['case'] as String? ?? config.caseId,
    };

    await _loadComponents(componentTypes);
  }

  Future<void> _loadComponentsFromCurrentConfig(Configuration config) async {
    final componentTypes = {
      'CPU': config.cpuId,
      'GPU': config.gpuId,
      'Motherboard': config.motherboardId,
      'RAM': config.ramId,
      'Storage': config.storageId,
      'PSU': config.psuId,
      'Case': config.caseId,
    };
    await _loadComponents(componentTypes);
  }

  Future<void> _loadComponents(Map<String, String?> componentTypes) async {
    final components = <String, Map<String, dynamic>>{};
    final componentFutures = <Future>[];

    for (final entry in componentTypes.entries) {
      if (entry.value != null) {
        final future = firestore.collection(getCollectionName(entry.key)).doc(entry.value).get().then((doc) {
          if (doc.exists) {
            components[entry.key] = doc.data()!;
          }
        });
        componentFutures.add(future);
      }
    }

    await Future.wait(componentFutures);

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
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(priceString, style: const TextStyle(color: Colors.white70, fontSize: 15)),
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

    final configProvider = Provider.of<ConfigurationProvider>(context, listen: false);

    try {
      await configProvider.saveCurrentConfiguration(
        _nameController.text.trim(),
        _descriptionController.text.trim(),
        _isPublic,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully!')),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
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
            : Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Configuration Name',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter configuration name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text(
                        'Make configuration public',
                        style: TextStyle(color: Colors.white),
                      ),
                      activeColor: Colors.green.shade600,
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                    if (configUser != null && configUser!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Created by: $configUser',
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
                        onPressed: _isSaving ? null : _saveConfiguration,
                        child: _isSaving
                            ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text(
                          'Save Configuration',
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
      ),
    );
  }
}
