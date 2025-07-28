import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:zavrsni/pages/top_screen.dart';
import 'configuration_provider.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => StorageScreenState();
}

class StorageScreenState extends State<StorageScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> storagesStream;
  String searchQuery = '';
  String? selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    storagesStream = firestore.collection('storages').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade900,
        child: const Icon(Icons.filter_list, color: Colors.white),
        onPressed: () async {
          final value = await showModalBottomSheet<String>(
            context: context,
            backgroundColor: Colors.black,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            builder: (context) {
              return FilterSheet(
                selectedType: selectedTypeFilter,
                onSelected: (String? type) {
                  Navigator.pop(context, type);
                },
              );
            },
          );
          if (value != null) {
            setState(() {
              selectedTypeFilter = value;
            });
          }
        },
      ),
      body: TopScreenWithSearch(
        title: 'Select Storage',
        hintText: 'Search Storage...',
        stream: storagesStream,
        builder: (context, data, searchQuery, sortAscending) {
          var storages = data.docs
              .where((doc) =>
              doc['name'].toString().toLowerCase().contains(searchQuery))
              .toList();

          // Filtering logic by type
          if (selectedTypeFilter != null && selectedTypeFilter != "All") {
            storages = storages
                .where((doc) =>
            (doc['type'] as String?)?.toLowerCase() ==
                selectedTypeFilter!.toLowerCase())
                .toList();
          }

          storages.sort((a, b) {
            final priceA = (a['price'] as num?)?.toDouble() ?? 0.0;
            final priceB = (b['price'] as num?)?.toDouble() ?? 0.0;
            return sortAscending
                ? priceA.compareTo(priceB)
                : priceB.compareTo(priceA);
          });

          return ListView.builder(
            itemCount: storages.length,
            itemBuilder: (context, index) {
              var storage = storages[index];
              return buildStorageCard(storage);
            },
          );
        },
      ),
    );

  }

  Widget buildStorageCard(QueryDocumentSnapshot storage) {
    final price = (storage['price'] as num?)?.toDouble();
    final priceString = price != null
        ? '\$${price.toStringAsFixed(2)}'
        : 'Price N/A';
    final capacity = storage['capacity'] as num? ?? 'N/A';
    final type = storage['type'] as String? ?? 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.withAlpha(65),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.storage, color: Colors.white, size: 36),
        title: Text(
          storage['name'] ?? 'Unknown Storage',
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
              'Capacity: $capacity GB',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text('Type: $type', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          openDetails(context, storage);
        },
      ),
    );
  }
}



void openDetails(BuildContext context, QueryDocumentSnapshot storage) {
  final images = (storage['images'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  final name = storage['name'] ?? 'Unknown RAM';
  final type = storage['type']?.toString() ?? 'N/A';
  final capacity = storage['capacity']?.toString() ?? 'N/A';
  final readSpeed = storage['readSpeed']?.toString() ?? 'N/A';
  final writeSpeed = storage['writeSpeed']?.toString() ?? 'N/A';
  final price = storage['price'] != null ? '\$${storage['price']}' : 'N/A';
  final manufacturer = storage['manufacturer'] ?? 'Unknown';
  final description = storage['description'] ?? 'No description available.';
  final warrantyYears = storage['warrantyYears']?.toString() ?? 'N/A';
  final formFactor = storage['formFactor'] ?? 'Unknown';
  final interface = storage['interface'] ?? 'Unknown';
  final tbw = storage['tbw']?.toString() ?? 'N/A';
  final protocol = storage['protocol'] ?? 'Unknown';
  final rpm = storage['rpm']?.toString() ?? 'N/A';
  final cache = storage['cache']?.toString() ?? 'N/A';

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
                          fit: BoxFit.fitWidth,
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
                      specRow('Read Speed (MB/s)', readSpeed),
                      specRow('Write Speed (MB/s)', writeSpeed),
                      specRow('Warranty Years', warrantyYears),
                      specRow('Form Factor', formFactor),
                      specRow('Interface', interface),
                      if (type == 'HDD') specRow('RPM', rpm),
                      if (type == 'HDD') specRow('Cache (MB)', cache),
                      if (type == 'SDD') specRow('TBW', tbw),
                      if (type == 'SDD') specRow('Protocol', protocol),
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
                ).setStorage(storage.id);
                Navigator.pushNamed(context, '/psu');
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

class FilterSheet extends StatelessWidget {
  final String? selectedType;
  final void Function(String?) onSelected;

  const FilterSheet({
    Key? key,
    required this.selectedType,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final types = ["All", "SSD", "HDD"];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: Text(
            "Filter by type",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...types.map(
              (type) => ListTile(
            title: Text(
              type,
              style: TextStyle(
                  color: selectedType == type ? Colors.green : Colors.white),
            ),
            leading: Radio<String>(
              value: type,
              groupValue: selectedType ?? "All",
              activeColor: Colors.green.shade900,
              onChanged: (val) => onSelected(val),
            ),
            onTap: () => onSelected(type),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
