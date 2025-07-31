import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OrderDetailPage extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailPage({super.key, required this.orderDoc});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);

    // Initialize local notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'order_channel_id',
          'Order Notifications',
          channelDescription: 'Notifications about order updates',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'order_payload',
    );
  }

  @override
  Widget build(BuildContext context) {
    final DocumentReference orderDocRef = widget.orderDoc.reference;

    return StreamBuilder<DocumentSnapshot>(
      stream: orderDocRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 1,
              foregroundColor: Colors.black,
              title: Text(
                "Order Details",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 1,
              foregroundColor: Colors.black,
              title: Text(
                "Order Details",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 1,
              foregroundColor: Colors.black,
              title: Text(
                "Order Details",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            body: const Center(child: Text('Order not found')),
          );
        }

        final liveOrderDoc = snapshot.data!;
        final liveOrderData = liveOrderDoc.data() as Map<String, dynamic>;

        return _buildOrderDetailContent(liveOrderDoc, liveOrderData);
      },
    );
  }

  Widget _buildOrderDetailContent(
    DocumentSnapshot orderDoc,
    Map<String, dynamic> orderData,
  ) {
    final Timestamp? timestamp = orderData['createdAt'];
    final DateTime? createdAt = timestamp?.toDate();
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)
        : 'Date not available';

    final String status = (orderData['status'] ?? 'unknown')
        .toString()
        .toLowerCase();
    final List<dynamic> items = orderData['items'] ?? [];

    const lightBackground = Color(0xFFF1F3F6);

    Color stepColor(int index, int currentStep, bool isRejected) {
      if (isRejected) return Colors.redAccent;
      if (index < currentStep) return Colors.green;
      if (index == currentStep) return Colors.orange;
      return Colors.grey[300]!;
    }

    Widget buildStatusProgressBar() {
      final steps = ['pending', 'accepted', 'delivered'];
      int currentStep = steps.indexOf(status);
      bool isRejected = status == 'rejected';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Column(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final isCurrent = i == currentStep && !isRejected;
                      return Transform.scale(
                        scale: isCurrent ? _scaleAnimation.value : 1.0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: stepColor(i, currentStep, isRejected),
                            shape: BoxShape.circle,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: stepColor(
                                        i,
                                        currentStep,
                                        isRejected,
                                      ).withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Icon(
                              i < currentStep
                                  ? Icons.check
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: stepColor(i, currentStep, isRejected),
                    ),
                  ),
                ],
              ),
              if (i != steps.length - 1)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: (isRejected || i >= currentStep)
                          ? Colors.grey[300]
                          : Colors.green,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
            ],
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'REJECTED',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 1,
        foregroundColor: Colors.black,
        title: Text(
          "Order Details",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ordered At Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.black),
                  const SizedBox(width: 10),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildStatusProgressBar(),
            const SizedBox(height: 10),
            Text(
              'Ordered Items',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ListTile(
                  leading: const Icon(Icons.inventory_2, color: Colors.black),
                  title: Text(
                    itemMap['itemId'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Quantity: ${itemMap['quantity'] ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color.fromARGB(156, 0, 0, 0),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // Conditional Actions
            if (status == 'delivered')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text("Confirm Delivery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      final firestore = FirebaseFirestore.instance;

                      await firestore.collection('history').add({
                        ...orderData,
                        'confirmedAt': Timestamp.now(),
                      });

                      await orderDoc.reference.delete();

                      // Show notification
                      await _showNotification(
                        "Order Confirmed",
                        "Your order has been confirmed and removed from active orders.",
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Order confirmed and removed!"),
                        ),
                      );

                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                    }
                  },
                ),
              )
            else if (status == 'rejected')
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit and Reorder"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Implement reorder/edit logic here."),
                      ),
                    );
                  },
                ),
              )
            else if (status == 'pending')
              Center(
                child: Text(
                  'Waiting for supplier to accept...',
                  style: GoogleFonts.poppins(
                    color: Colors.red[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (status == 'accepted')
              Center(
                child: Text(
                  'Order has been accepted!',
                  style: GoogleFonts.poppins(
                    color: Colors.green[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
