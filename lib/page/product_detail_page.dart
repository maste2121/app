import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/page/cart_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int selectedsize = 0;

  void onTap() {
    if (selectedsize != 0) {
      Provider.of<CartProvider>(context, listen: false).addproduct({
        'id': widget.product['id'] ?? DateTime.now().toString(),
        'title': widget.product['title'],
        'price': widget.product['price'],
        'sizes': selectedsize,
        'imageUrl': widget.product['imageUrl'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rawSizes =
        widget.product['sizes'] as List<dynamic>? ?? [1, 2, 3, 45];
    final List<int> sizes = rawSizes.map((e) => (e as num).toInt()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        // ✅ Makes the entire page scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                widget.product['title']?.toString() ?? 'No Title',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Product Image
            Center(
              child: // Inside ProductDetailPage build method, replace the Image.network part:
                  Hero(
                tag: widget.product['imageUrl'] ?? '',
                child:
                    widget.product['imageUrl'].toString().startsWith(
                          'data:image',
                        )
                        ? Image.memory(
                          base64Decode(
                            widget.product['imageUrl']
                                .toString()
                                .split(',')
                                .last,
                          ),
                          height: 300,
                          fit: BoxFit.contain,
                        )
                        : Image.network(
                          widget.product['imageUrl']?.toString() ?? '',
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 100),
                        ),
              ),
            ),

            const SizedBox(height: 20),

            // Main Details Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(245, 247, 249, 1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Rating Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.product['price']} ETB',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          SizedBox(width: 5),
                          Text(
                            "4.8 (120 Reviews)",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Select Size",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Sizes ListView
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sizes.length,
                      itemBuilder: (BuildContext context, int index) {
                        final size = sizes[index];
                        final isSelected = selectedsize == size;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => selectedsize = size),
                            child: Chip(
                              label: Text(size.toString()),
                              backgroundColor:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white,
                              labelStyle: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color:
                                    isSelected
                                        ? Colors.transparent
                                        : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // ✅ NEW: REVIEWS SECTION (Inspiration)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Customer Reviews",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("View All"),
                      ),
                    ],
                  ),

                  // Mock Review 1
                  _buildReviewItem(
                    name: "Abel T.",
                    rating: 5,
                    comment:
                        "The quality is amazing for campus use. Very comfortable!",
                  ),

                  // Mock Review 2
                  _buildReviewItem(
                    name: "Sara K.",
                    rating: 4,
                    comment:
                        "Looks exactly like the photo. Fast delivery inside the dorms.",
                  ),

                  const SizedBox(height: 30),

                  // Add To Cart Button
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 65),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'ADD TO CART',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Helper widget for a single review
  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String comment,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 14,
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
