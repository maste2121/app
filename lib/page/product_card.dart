import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/page/favorites_provider.dart';
import 'package:shopping_app/page/cart_provider.dart';

class ProductCard extends StatefulWidget {
  final String title;
  final double price;
  final double oldPrice;
  final String image;
  final Color background;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.oldPrice,
    required this.image,
    required this.background,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isOrdering = false;

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addToCart() {
    // ✅ Use null-safe Title as ID
    Provider.of<CartProvider>(context, listen: false).addproduct({
      'id': widget.title,
      'title': widget.title,
      'price': widget.price,
      'imageUrl': widget.image,
      'company': 'All',
      'sizes': 40,
    });
    _showMsg("Added to cart! 🛒", Colors.blueGrey);
  }

  Future<void> _placeOrder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMsg("Please login to order", Colors.orange);
      return;
    }
    setState(() => _isOrdering = true);
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'productTitle': widget.title,
        'price': widget.price,
        'imageUrl': widget.image,
        'buyerId': user.uid,
        'buyerEmail': user.email,
        'status': 'pending',
        'orderDate': FieldValue.serverTimestamp(),
      });
      if (mounted) _showMsg("Order placed successfully! ✅", Colors.green);
    } catch (e) {
      if (mounted) _showMsg("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  // ✅ Robust Image Builder with Null checks
  Widget _buildProductImage(String imageStr) {
    if (imageStr.isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }

    if (imageStr.startsWith('data:image')) {
      try {
        final base64String = imageStr.split(',').last.trim();
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
    }
    return Image.network(
      imageStr,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Logic: Ensure oldPrice is at least equal to price to avoid negative %
    double safeOldPrice =
        widget.oldPrice > widget.price ? widget.oldPrice : widget.price;

    int discountPercent = 0;
    if (safeOldPrice > widget.price && safeOldPrice > 0) {
      discountPercent =
          (((safeOldPrice - widget.price) / safeOldPrice) * 100).round();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. IMAGE SECTION ---
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: Container(
                    color: const Color(0xFFF7F7F7),
                    // ✅ FIXED: Hero tag logic to prevent Null error
                    child: Hero(
                      tag: widget.image.isEmpty ? widget.title : widget.image,
                      child: _buildProductImage(widget.image),
                    ),
                  ),
                ),
                if (discountPercent > 10)
                  Positioned(
                    top: 5,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Choice",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, fav, child) {
                      bool isLiked = fav.isFavorite(widget.title);
                      return GestureDetector(
                        onTap:
                            () => fav.toggleFavorite({
                              'title': widget.title,
                              'price': widget.price,
                              'imageUrl': widget.image,
                            }),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.1),
                          radius: 12,
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                            size: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // --- 2. DETAILS SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title, // String guaranteed non-null via constructor
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFFF9500),
                        size: 10,
                      ),
                      const Text(
                        " 4.8",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('orders')
                                  .where(
                                    'productTitle',
                                    isEqualTo: widget.title,
                                  )
                                  .snapshots(),
                          builder: (context, snapshot) {
                            int sold =
                                snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;
                            return Text(
                              "$sold sold",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.price.toStringAsFixed(0)} ETB",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                    ),
                  ),
                  if (discountPercent > 0)
                    Row(
                      children: [
                        Text(
                          safeOldPrice.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "-$discountPercent%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // --- 3. ACTIONS (BUY & CART) ---
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _addToCart,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child:
                            _isOrdering
                                ? const Center(
                                  child: SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : SizedBox(
                                  height: 28,
                                  child: ElevatedButton(
                                    onPressed: () => _placeOrder(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Buy Now",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
