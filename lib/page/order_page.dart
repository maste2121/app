import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shopping_app/page/notifications_page.dart';
import 'package:shopping_app/service/auth_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

  // ✅ ADDED: Search Query State
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    bool adminStatus = await _authService.isAdmin();
    if (mounted) setState(() => _isAdmin = adminStatus);
  }

  // ✅ ADMIN ACTION: Update Status & Notify
  Future<void> _updateStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
      'adminNote': 'Your order is now $newStatus', // Simple notification
    });
  }

  // ✅ ADMIN ACTION: Delete Order
  Future<void> _deleteOrder(String orderId) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Delete Order?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Check if screen is mobile (width less than 600)
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(245, 247, 249, 1),
      appBar: AppBar(
        title: Text(_isAdmin ? "Admin: Manage Orders" : "My Orders"),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          // ✅ NOTIFICATION ICON
          StreamBuilder<QuerySnapshot>(
            stream:
                _isAdmin
                    ? FirebaseFirestore.instance
                        .collection('orders')
                        .where('hasUnreadMessage', isEqualTo: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('orders')
                        .where('buyerId', isEqualTo: _currentUid)
                        .where('hasUnreadMessage', isEqualTo: true)
                        .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                // Count only messages NOT sent by the current user
                unreadCount =
                    snapshot.data!.docs
                        .where(
                          (doc) => doc['lastMessageSenderId'] != _currentUid,
                        )
                        .length;
              }

              return IconButton(
                icon: Badge(
                  label: Text(unreadCount.toString()),
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: Colors.red,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  // ✅ NAVIGATE TO SEPARATE PAGE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => NotificationsPage(
                            isAdmin: _isAdmin,
                            currentUid: _currentUid,
                          ),
                    ),
                  );
                },
              );
            },
          ),
        ],
        // ✅ ADDED: Search Bar for Admin in the AppBar
        bottom:
            _isAdmin
                ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search by buyer email...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _isAdmin
                ? FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('orderDate', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('orders')
                    .where('buyerId', isEqualTo: _currentUid)
                    .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          // ✅ ADDED: Filtering logic for Search
          var orders = snapshot.data!.docs;
          if (_isAdmin && _searchQuery.isNotEmpty) {
            orders =
                orders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email =
                      data['buyerEmail']?.toString().toLowerCase() ?? "";
                  return email.contains(_searchQuery);
                }).toList();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final order = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    ListTile(
                      // ✅ UPDATED: Hide leading image if isMobile is true
                      leading:
                          isMobile
                              ? null
                              : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      order['imageUrl'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // ✅ RED DOT NOTIFICATION
                                  if (order['hasUnreadMessage'] == true &&
                                      order['lastMessageSenderId'] !=
                                          _currentUid)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        height: 12,
                                        width: 12,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          border: Border.fromBorderSide(
                                            BorderSide(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      title: Text(
                        order['productTitle'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // ✅ REMOVED subtitle (lastMessage) to keep card clean
                      trailing: _buildStatusChip(order['status'] ?? 'pending'),
                    ),

                    if (order['adminNote'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "🔔 ${order['adminNote']}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ✅ ADDED: Chat Button for both Admin and Buyer
                          TextButton.icon(
                            onPressed: () {
                              // ✅ MARK AS READ WHEN OPENING
                              FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(orderId)
                                  .update({'hasUnreadMessage': false});

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatScreen(
                                        orderId: orderId,
                                        productTitle: order['productTitle'],
                                        isAdmin: _isAdmin,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat,
                              size: 18,
                              color: Colors.blue,
                            ),
                            label: const Text("Chat"),
                          ),

                          if (_isAdmin) ...[
                            TextButton.icon(
                              onPressed:
                                  () => _updateStatus(orderId, "delivered"),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              label: const Text("Deliver"),
                            ),
                            TextButton.icon(
                              onPressed:
                                  () => _updateStatus(orderId, "cancelled"),
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.orange,
                                size: 18,
                              ),
                              label: const Text("Cancel"),
                            ),
                            IconButton(
                              onPressed: () => _deleteOrder(orderId),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color =
        status == 'pending'
            ? Colors.grey
            : (status == 'delivered' ? Colors.green : Colors.red);
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}

// ✅ NEW WIDGET: Chat Screen
class ChatScreen extends StatefulWidget {
  final String orderId;
  final String productTitle;
  final bool isAdmin; // Pass role to identify sender

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.productTitle,
    required this.isAdmin,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    final text = _msgController.text.trim();
    _msgController.clear();

    // 1. Add to Sub-collection
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': _uid,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // 2. ✅ Update Order Document for Notifications/Previews
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'lastMessage': text,
          'lastMessageSenderId': _uid,
          'hasUnreadMessage': true,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat: ${widget.productTitle}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .doc(widget.orderId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final data = msgs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _uid;

                    // ✅ IDENTIFY SENDER
                    String senderLabel =
                        isMe ? "You" : (widget.isAdmin ? "Buyer" : "Admin");

                    return Column(
                      crossAxisAlignment:
                          isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            senderLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Align(
                          alignment:
                              isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isMe
                                      ? const Color.fromRGBO(254, 206, 1, 1)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(data['text'] ?? ""),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: const InputDecoration(
                      hintText: "Write a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _send,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
