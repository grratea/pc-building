import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/cpu_screen.dart';
import 'package:zavrsni/pages/top_screen.dart';
import 'configuration_provider.dart';

class GpuScreen extends StatefulWidget {
  const GpuScreen({super.key});

  @override
  State<GpuScreen> createState() => GpuScreenState();
}

class GpuScreenState extends State<GpuScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> gpusStream;
  String searchQuery = '';
  double? cpuPower;

  static const double minRatio = 0.65;
  static const double maxRatio = 2;

  @override
  void initState() {
    super.initState();
    gpusStream = firestore.collection('gpus').snapshots();
    loadCpuPower();
  }

  Future<void> loadCpuPower() async {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final cpuId = configProvider.currentConfig.cpuId;

    if (cpuId != null) {
      final cpuDoc = await firestore.collection('cpus').doc(cpuId).get();
      if (cpuDoc.exists) {
        final cpuData = cpuDoc.data() as Map<String, dynamic>;
        setState(() {
          cpuPower = (cpuData['power'] as num?)?.toDouble();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopScreenWithSearch(
      title: 'Select Graphics Card',
      hintText: 'Select Graphics Cards...',
      stream: gpusStream,
      builder: (context, data, searchQuery, sortAscending) {
        var gpus = data.docs
            .where(
              (doc) =>
                  doc['name'].toString().toLowerCase().contains(searchQuery),
            )
            .toList();

        gpus.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;

          return sortAscending
              ? priceA.compareTo(priceB)
              : priceB.compareTo(priceA);
        });

        // LOGIKA ZA RATIO
        var filteredGpus = gpus.where((gpu) {
          final gpuPower = (gpu['power'] as num?)?.toDouble();
          if (cpuPower == null || gpuPower == null) return true;
          final ratio = (gpuPower / 1.7) / cpuPower!;
          return ratio >= minRatio && ratio <= maxRatio;
        }).toList();

        return ListView.builder(
          itemCount: filteredGpus.length,
          itemBuilder: (context, index) {
            var gpu = filteredGpus[index];
            final gpuPower = (gpu['power'] as num?)?.toDouble();
            final ratio = cpuPower != null && gpuPower != null
                ? (gpuPower / 1.7) / cpuPower!
                : null;

            return buildGpuCard(gpu, ratio);
          },
        );
      },
    );
  }

  Widget buildGpuCard(QueryDocumentSnapshot gpu, double? ratio) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(
          Icons.videogame_asset,
          color: Colors.white,
          size: 36,
        ),
        title: Text(
          gpu['name'] ?? 'Unknown GPU',
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
              '\$${(gpu['price'] as num?)?.toStringAsFixed(2) ?? 'Price N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Memory: ${gpu['memory'] ?? 'N/A'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (ratio != null) ...[
              const SizedBox(height: 4),
              Text(
                'CPU/GPU Ratio: ${ratio.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, color: Colors.white70,),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          openDetails(context, gpu);
        },
      ),
    );
  }
}

void openDetails(BuildContext context, QueryDocumentSnapshot gpu) {
  final images = (gpu['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = gpu['name'] ?? 'Unknown GPU';
  final price = gpu['price'] != null ? '\$${gpu['price']}' : 'N/A';
  final manufacturer = gpu['manufacturer'] ?? 'Unknown';
  final power = gpu['power']?.toString() ?? 'N/A';
  final dimensions = (gpu['dimension'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final bus = gpu['bus']?.toString() ?? 'N/A';
  final gpuClock = gpu['gpuClock']?.toString() ?? 'N/A';
  final memory = gpu['memory']?.toString() ?? 'N/A';
  final description = gpu['description'] ?? 'No description available.';

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
                      viewportFraction: 0.9,
                    ),
                    items: images.map((imgUrl) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.contain,
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
                      specRow('Bus', bus),
                      specRow('Gpu Clock (MHz)', gpuClock),
                      specRow('Memory', memory),
                      specRow('Length (mm)', dimensions[0]),
                      specRow('Width (mm)', dimensions[1]),
                      specRow('Height (mm)', dimensions[2]),
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
                ).setGpu(gpu.id);
                Navigator.pushNamed(context, '/ram');
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
