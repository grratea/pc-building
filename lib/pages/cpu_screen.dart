import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'top_screen.dart';
import 'configuration_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CpuScreen extends StatefulWidget {
  const CpuScreen({super.key});

  @override
  State<CpuScreen> createState() => _CpuScreenState();
}

class _CpuScreenState extends State<CpuScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> cpusStream;

  @override
  void initState() {
    super.initState();
    cpusStream = firestore.collection('cpus').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return TopScreenWithSearch(
      title: 'Select CPU',
      hintText: 'Search CPUs...',
      stream: cpusStream,
      builder: (context, data, searchQuery, sortAscending) {
        var cpus = data.docs
            .where(
              (doc) =>
                  doc['name'].toString().toLowerCase().contains(searchQuery),
            )
            .toList();

        cpus.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
          return sortAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });

        return ListView.builder(
          itemCount: cpus.length,
          itemBuilder: (context, index) {
            var cpu = cpus[index];
            return buildCpuCard(cpu);
          },
        );
      },
    );
  }

  Widget buildCpuCard(QueryDocumentSnapshot cpu) {
    final price = (cpu['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const Icon(Icons.memory, color: Colors.white, size: 36),
        title: Text(
          cpu['name'] ?? 'Unnamed CPU',
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
            Text(
              priceString,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (cpu['socket'] != null)
              Text(
                'Socket: ${cpu['socket']}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          // print('Selected CPU: ${cpu['name']}');   // debugging
          openDetails(context, cpu);
        },
      ),
    );
  }
}

void openDetails(BuildContext context, QueryDocumentSnapshot cpu) {
  final images = (cpu['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = cpu['name'] ?? 'Unknown CPU';
  final price = cpu['price'] != null ? '\$${cpu['price']}' : 'N/A';
  final manufacturer = cpu['manufacturer'] ?? 'Unknown';
  final power = cpu['power']?.toString() ?? 'N/A';
  final socket = cpu['socket'] ?? 'Unknown';
  final cores = cpu['cores']?.toString() ?? 'N/A';
  final threads = cpu['threads']?.toString() ?? 'N/A';
  final frequency = cpu['frequency']?.toString() ?? 'N/A';
  final description = cpu['description'] ?? 'No description available.';

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
                      specRow('Cores', cores),
                      specRow('Threads', threads),
                      specRow('Frequency (GHz)', frequency),
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
                final socket = cpu['socket'] as String? ?? 'Unknown';
                Provider.of<ConfigurationProvider>(
                  context,
                  listen: false,
                ).setCpu(cpu.id, socket);
                Navigator.pushNamed(context, '/mobo');
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
