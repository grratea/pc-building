import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/top_screen.dart';
import 'configuration_provider.dart';

class RamScreen extends StatefulWidget {
  const RamScreen({super.key});

  @override
  State<RamScreen> createState() => RamScreenState();
}

class RamScreenState extends State<RamScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> ramsStream;
  String searchQuery = '';
  String? moboDdrType;

  @override
  void initState() {
    super.initState();
    ramsStream = firestore.collection('rams').snapshots();
    loadMoboDdrType();
  }

  Future<void> loadMoboDdrType() async {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final moboId = configProvider.currentConfig.motherboardId;

    if (moboId != null) {
      final moboDoc = await firestore.collection('mobos').doc(moboId).get();
      if (moboDoc.exists) {
        final moboData = moboDoc.data() as Map<String, dynamic>;
        setState(() {
          moboDdrType = (moboData['ddrType'] as String?)?.toUpperCase();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopScreenWithSearch(
      title: 'Select RAM',
      hintText: 'Select RAMs...',
      stream: ramsStream,
      builder: (context, data, searchQuery, sortAscending) {
        var rams =
            data.docs.where((doc) {
              final ramDdr = (doc['type'] as String?)?.toUpperCase();
              final name = (doc['name'] as String?)?.toLowerCase() ?? '';

              final ddrCompatible =
                  moboDdrType == null || ramDdr == moboDdrType;
              final matchesSearch = name.contains(searchQuery);

              return ddrCompatible && matchesSearch;
            }).toList();

        rams.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;

          return sortAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });

        return Column(
          children: [
            if (moboDdrType != null)
              Padding(
                padding: EdgeInsets.all(8),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade900,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'SHOWING RAM FOR $moboDdrType TYPE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: rams.length,
                itemBuilder: (context, index) {
                  var ram = rams[index];
                  return buildRamCard(ram);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildRamCard(QueryDocumentSnapshot ram) {
    final price = (ram['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';
    final speed = ram['speed'] as num? ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.memory, color: Colors.white, size: 36),
        title: Text(
          ram['name'] ?? 'Unknown RAM',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
              'Speed: $speed MHz',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          openDetails(context, ram);
        },
      ),
    );
  }
}


void openDetails(BuildContext context, QueryDocumentSnapshot ram) {
  final images = (ram['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = ram['name'] ?? 'Unknown RAM';
  final type = ram['type']?.toString() ?? 'N/A';
  final capacity = ram['capacity']?.toString() ?? 'N/A';
  final speed = ram['speed']?.toString() ?? 'N/A';
  final price = ram['price'] != null ? '\$${ram['price']}' : 'N/A';
  final manufacturer = ram['manufacturer'] ?? 'Unknown';
  final description = ram['description'] ?? 'No description available.';
  final latency = ram['latency']?.toString() ?? 'N/A';
  final modules = ram['modules']?.toString() ?? 'N/A';
  final voltage = ram['voltage']?.toString() ?? 'N/A';

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
                      specRow('Type', type),
                      specRow('Capacity (GB)', capacity),
                      specRow('Speed (MHz)', speed),
                      specRow('Latency', latency),
                      specRow('Modules', modules),
                      specRow('Voltage (V)', voltage),
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
                ).setRam(ram.id);
                Navigator.pushNamed(context, '/storage');
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
