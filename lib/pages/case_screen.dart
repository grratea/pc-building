import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/top_screen.dart';
import 'configuration_provider.dart';

class CaseScreen extends StatefulWidget {
  const CaseScreen({super.key});

  @override
  State<CaseScreen> createState() => CaseScreenState();
}

class CaseScreenState extends State<CaseScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> casesStream;
  String searchQuery = '';
  num? gpuLength;

  @override
  void initState() {
    super.initState();
    casesStream = firestore.collection('cases').snapshots();
    loadGpuLength();
  }

  Future<void> loadGpuLength() async {
    final configProvider = Provider.of<ConfigurationProvider>(
      context,
      listen: false,
    );
    final gpuId = configProvider.currentConfig.gpuId;

    if (gpuId != null) {
      final gpuDoc = await firestore.collection('gpus').doc(gpuId).get();
      if (gpuDoc.exists) {
        final gpuData = gpuDoc.data() as Map<String, dynamic>;
        setState(() {
          if (gpuData['dimension'] is List && gpuData['dimension'].isNotEmpty) {
            gpuLength = (gpuData['dimension'][0] as num?)?.toDouble();
          } else {
            gpuLength = null;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopScreenWithSearch(
      title: 'Select Case',
      hintText: 'Search Cases...',
      stream: casesStream,
      builder: (context, data, searchQuery, sortAscending) {
        var cases = data.docs.where((doc) {
          final maxGpuLength = (doc['maxGpuLength'] as num?)?.toDouble();
          final name = doc['name'].toString().toLowerCase();

          return maxGpuLength != null &&
              maxGpuLength >= gpuLength! &&
              name.contains(searchQuery);
        }).toList();

        cases.sort((a, b) {
          final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
          final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;

          if (priceA != priceB) {
            return sortAscending
                ? priceA.compareTo(priceB)
                : priceB.compareTo(priceA);
          }
          return a['name'].toString().compareTo(b['name'].toString());
        });

        return Column(
          children: [
            if (gpuLength != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Your GPU length: ${gpuLength!.toStringAsFixed(0)} mm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'No GPU selected.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  var pcCase = cases[index];
                  return buildCaseCard(context, pcCase, gpuLength);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildCaseCard(
    BuildContext context,
    QueryDocumentSnapshot pcCase,
    num? gpuLength,
  ) {
    final maxGpuLength = (pcCase['maxGpuLength'] as num?)?.toDouble();
    final price = (pcCase['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.computer, color: Colors.white, size: 36),
        title: Text(
          pcCase['name'] ?? 'Unknown Case',
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
            Text(
              'Max GPU Length: ${maxGpuLength?.toStringAsFixed(0) ?? 'N/A'} mm',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
            openDetails(context, pcCase);
        },
      ),
    );
  }
}

void openDetails(BuildContext context, QueryDocumentSnapshot pcCase) {
  final images = (pcCase['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = pcCase['name'] ?? 'Unknown PcCase';
  final formFactor = pcCase['formFactor'] as String? ?? 'N/A';
  final type = pcCase['type'] as String? ?? 'N/A';
  final dimensions = pcCase['dimensions'] as String? ?? 'N/A';
  final maxGpuLength = pcCase['maxGpuLength']?.toString() ?? 'N/A';
  final maxCpuCoolerHeight = pcCase['maxCpuCoolerHeight']?.toString() ?? 'N/A';
  final psuFormFactor = pcCase['psuFormFactor'] ?? 'Unknown';
  final price = pcCase['price'] != null ? '\$${pcCase['price']}' : 'N/A';
  final manufacturer = pcCase['manufacturer'] ?? 'Unknown';
  final description = pcCase['description'] ?? 'No description available.';
  final rgb = pcCase['rgb'] ?? 'Unknown';
  final glassPanel = pcCase['glassPanel'] ?? 'Unknown';

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
                      specRow('Form Factor', formFactor),
                      specRow('Type', type),
                      // specRow('Max GPU Length (mm)', maxGpuLength),
                      specRow('Psu Form Factor', psuFormFactor),
                      specRow('Dimensions (mm)', dimensions),
                      specRow('RGB', rgb),
                      specRow('Glass Panel', glassPanel),
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
                ).setCase(pcCase.id);
                Navigator.pushNamed(context, '/summary');
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
