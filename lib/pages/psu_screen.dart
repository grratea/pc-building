import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/top_screen.dart';
import 'configuration_provider.dart';

class PsuScreen extends StatefulWidget {
  const PsuScreen({super.key});

  @override
  State<PsuScreen> createState() => PsuScreenState();
}

class PsuScreenState extends State<PsuScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> psusStream;
  String searchQuery = '';
  double requiredPower = 0.0;

  @override
  void initState() {
    super.initState();
    psusStream = firestore.collection('psus').snapshots();
    calculateRequiredPower();
  }

  Future<void> calculateRequiredPower() async {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    double totalPower = 0.0;

    if (configProvider.currentConfig.cpuId != null) {
      final cpuDoc = await firestore
          .collection('cpus')
          .doc(configProvider.currentConfig.cpuId)
          .get();
      if (cpuDoc.exists) {
        totalPower += (cpuDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (configProvider.currentConfig.motherboardId != null) {
      final moboDoc = await firestore
          .collection('mobos')
          .doc(configProvider.currentConfig.motherboardId)
          .get();
      if (moboDoc.exists) {
        totalPower += (moboDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (configProvider.currentConfig.gpuId != null) {
      final gpuDoc = await firestore
          .collection('gpus')
          .doc(configProvider.currentConfig.gpuId)
          .get();
      if (gpuDoc.exists) {
        totalPower += (gpuDoc.data()?['power'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (configProvider.currentConfig.ramId != null) {
      totalPower += 10;
    }

    if (configProvider.currentConfig.storageId != null) {
      totalPower += 11;
    }

    setState(() {
      requiredPower = totalPower * 1.2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TopScreenWithSearch(
        title: 'Select Power Supply',
        hintText: 'Search PSUs...',
        stream: psusStream,
        builder: (context, data, searchQuery, sortAscending) {
          var psus =
          data.docs.where((doc) {
            final wattage = (doc['wattage'] as num?)?.toDouble() ?? 0.0;
            final name = doc['name'].toString().toLowerCase();
            return wattage >= requiredPower &&
                name.contains(searchQuery);
          }).toList();

          psus.sort((a, b) {
            final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
            final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
            return sortAscending
                ? priceA.compareTo(priceB)
                : priceB.compareTo(priceA);
          });

          return Column(
            children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Required Power: ${requiredPower.toStringAsFixed(0)} W',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: psus.length,
                  itemBuilder: (context, index) {
                    var psu = psus[index];
                    return buildPsuCard(psu);
                  },
                ),
              ),
            ],
          );
        }
    );
  }

  Widget buildPsuCard(QueryDocumentSnapshot psu) {
    final wattage = psu['wattage']?.toString() ?? 'N/A';
    final price = (psu['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';
    final efficiency = psu['efficiency'] as String? ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.power, color: Colors.white, size: 36),
        title: Text(
          psu['name'] ?? 'Unknown PSU',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(priceString, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text(
              'Wattage: $wattage W',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Efficiency: $efficiency',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          openDetails(context, psu);
        },
      ),
    );
  }
}

void openDetails(BuildContext context, QueryDocumentSnapshot psu) {
  final images = (psu['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = psu['name'] ?? 'Unknown RAM';
  final wattage = psu['wattage']?.toString() ?? 'N/A';
  final formFactor = psu['formFactor'] as String? ?? 'N/A';
  final modularity = psu['modularity'] as String? ?? 'N/A';
  final efficiency = psu['efficiency'] as String? ?? 'N/A';
  final warrantyYears = psu['warrantyYears']?.toString() ?? 'N/A';
  final price = psu['price'] != null ? '\$${psu['price']}' : 'N/A';
  final manufacturer = psu['manufacturer'] ?? 'Unknown';
  final description = psu['description'] ?? 'No description available.';
  final fanSize = psu['fanSize']?.toString() ?? 'N/A';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (images.isNotEmpty)
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      viewportFraction: 0.85,
                    ),
                    items: images.map((imgUrl) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          height: 180,
                        ),
                      );
                    }).toList(),
                  )
                else
                  Container(
                    height: 180,
                    alignment: Alignment.center,
                    child: Icon(Icons.memory, color: Colors.white38, size: 72),
                  ),
                const SizedBox(height: 18),
                // Name
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // Description
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                // Attribute table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: IntrinsicColumnWidth(),
                      1: FlexColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      specRow('Price', price),
                      specRow('Manufacturer', manufacturer),
                      specRow('Wattage (W)', wattage),
                      specRow('Form Factor', formFactor),
                      specRow('Modularity', modularity),
                      specRow('Efficiency', efficiency),
                      specRow('Warranty Years', warrantyYears),
                      specRow('Fan Size (mm)', fanSize),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Provider.of<ConfigurationProvider>(
                  context,
                  listen: false,
                ).setPsu(psu.id);
                Navigator.pushNamed(context, '/case');
              },
              child: const Text("SAVE"),
            ),
          ),
        ],
      );
    },
  );
}

TableRow specRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ],
  );
}
