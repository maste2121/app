import 'package:flutter/material.dart';
import 'package:shopping_app/page/cart_page.dart';
import 'package:shopping_app/page/order_page.dart';
import 'package:shopping_app/page/product_list.dart';
import 'package:shopping_app/page/favorites_page.dart';
import 'package:shopping_app/page/profile_page.dart';
import 'package:shopping_app/service/auth_service.dart'; // ✅ Import your service
import 'package:shopping_app/page/add_product_screen.dart'; // ✅ You will create this next

class Homescrean extends StatefulWidget {
  const Homescrean({super.key});

  @override
  State<Homescrean> createState() => _HomescreanState();
}

class _HomescreanState extends State<Homescrean> {
  int currentPage = 0;
  bool _isAdminUser = false; // ✅ State to track if user is admin
  final AuthService _authService = AuthService(); // ✅ Instance of AuthService

  final List<Widget> pages = const [
    ProductList(),
    FavoritesPage(),
    OrderPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkRole(); // ✅ Check the user role as soon as the app starts
  }

  // ✅ Function to check admin status from Firestore
  Future<void> _checkRole() async {
    bool adminStatus = await _authService.isAdmin();
    if (mounted) {
      setState(() {
        _isAdminUser = adminStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: currentPage, children: pages),

      // ✅ ONLY SHOW THE ADD PRODUCT BUTTON IF ADMIN IS TRUE
      floatingActionButton:
          _isAdminUser
              ? FloatingActionButton(
                backgroundColor: const Color.fromRGBO(
                  254,
                  206,
                  1,
                  1,
                ), // Your brand yellow
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.black, size: 30),
              )
              : null, // Return null (nothing) if the user is a regular student

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: NavigationBar(
          selectedIndex: currentPage,
          onDestinationSelected: (index) => setState(() => currentPage = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite_rounded, color: Colors.red),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
