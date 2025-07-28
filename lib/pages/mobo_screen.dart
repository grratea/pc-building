import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'configuration_provider.dart';
import 'top_screen.dart';

class MoboScreen extends StatefulWidget {
  const MoboScreen({super.key});

  @override
  State<MoboScreen> createState() => MoboScreenState();
}

class MoboScreenState extends State<MoboScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> mobosStream;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final socket = configProvider.cpuSocket;

    if (socket != null) {
      mobosStream = firestore
          .collection('mobos')
          .where('socket', isEqualTo: socket)
          .snapshots();
    } else {
      mobosStream = firestore.collection('mobos').snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final cpuSocket = configProvider.cpuSocket;
    return TopScreenWithSearch(
      title: 'Select Motherboard',
      hintText: 'Select Motherboards...',
      stream: mobosStream,
      builder: (context, data, searchQuery, sortAscending) {
        var mobos = data.docs
            .where(
              (doc) =>
                  doc['name'].toString().toLowerCase().contains(searchQuery),
            )
            .toList();

        mobos.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;

          return sortAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });

        return Column(
          children: [
            if (cpuSocket != null)
              Padding(
                padding: EdgeInsets.all(8),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade900,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'SHOWING MOTHERBOARDS FOR $cpuSocket SOCKET',
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
                itemCount: mobos.length,
                itemBuilder: (context, index) {
                  var mobo = mobos[index];
                  return buildMoboCard(mobo);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildMoboCard(QueryDocumentSnapshot mobo) {
    final price = (mobo['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const Icon(Icons.build_sharp, color: Colors.white, size: 36),
        title: Text(
          mobo['name'] ?? 'Unnamed Motherboard',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (mobo['socket'] != null)
              Text(
                'Socket: ${mobo['socket']}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          openDetails(context, mobo);
        },
      ),
    );
  }
}

void openDetails(BuildContext context, QueryDocumentSnapshot mobo) {
  final images = (mobo['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = mobo['name'] ?? 'Unknown MOBO';
  final price = mobo['price'] != null ? '\$${mobo['price']}' : 'N/A';
  final manufacturer = mobo['manufacturer'] ?? 'Unknown';
  final power = mobo['power']?.toString() ?? 'N/A';
  final socket = mobo['socket'] ?? 'Unknown';
  final ramSlots = mobo['ramSlots']?.toString() ?? 'N/A';
  final chipset = mobo['chipset']?.toString() ?? 'N/A';
  final ddrType = mobo['ddrType']?.toString() ?? 'N/A';
  final description = mobo['description'] ?? 'No description available.';
  final formFactor = mobo['formFactor']?.toString() ?? 'N/A';

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
                      specRow('Power (W)', power),
                      specRow('Socket', socket),
                      specRow('Ram Slots', ramSlots),
                      specRow('Chipset', chipset),
                      specRow('RAM Memory', ddrType),
                      specRow('Form Factor', formFactor),
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
                ).setMotherboard(mobo.id);
                Navigator.pushNamed(context, '/gpu');
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
