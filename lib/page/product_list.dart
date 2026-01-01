import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopping_app/page/product_card.dart';
import 'package:shopping_app/page/product_detail_page.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final List<String> filters = const ['All', 'Addidas', 'Nike', 'Beta'];
  late String selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = filters[0];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // AliExpress uses high density. 2 columns on mobile, many on desktop.
    int crossAxisCount = size.width < 600 ? 2 : (size.width < 1000 ? 4 : 6);

    return Scaffold(
      // AliExpress style: Light gray background for the whole feed
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER / SEARCH SECTION ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for shoes...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                ],
              ),
            ),

            // --- TABS / FILTER SECTION ---
            Container(
              color: Colors.white,
              height: 50,
              child: ListView.builder(
                itemCount: filters.length,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = filter),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? Colors.red : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- LIVE PRODUCT GRID ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    (selectedFilter == 'All')
                        ? FirebaseFirestore.instance
                            .collection('products')
                            .orderBy('createdAt', descending: true)
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('products')
                            .where('company', isEqualTo: selectedFilter)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading data"));
                  }

                  final products = snapshot.data!.docs;

                  if (products.isEmpty) {
                    return const Center(child: Text("No products found"));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      // Set to 0.58 to handle the extra details
                      childAspectRatio: 0.58,
                    ),
                    itemBuilder: (context, index) {
                      final data =
                          products[index].data() as Map<String, dynamic>;

                      // ✅ STEP 1: SAFE STRING PARSING (Fixes the Null error)
                      String title = data['title']?.toString() ?? 'No Title';
                      String imageUrl = data['imageUrl']?.toString() ?? '';

                      // ✅ STEP 2: SAFE NUMBER PARSING
                      double price = (data['price'] as num?)?.toDouble() ?? 0.0;
                      double oldPrice =
                          (data['oldPrice'] as num?)?.toDouble() ?? price;

                      return ProductCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => ProductDetailPage(product: data),
                            ),
                          );
                        },
                        title: title,
                        price: price,
                        oldPrice: oldPrice,
                        image: imageUrl,
                        background: const Color(0xFFF7F7F7),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
