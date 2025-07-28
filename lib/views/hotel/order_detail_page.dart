  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart';
  import 'package:google_fonts/google_fonts.dart';

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

      // Start animation loop for pulsing current step
      _controller.repeat(reverse: true);
    }

    @override
    void dispose() {
      _controller.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final orderData = widget.orderDoc.data() as Map<String, dynamic>;
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

      Color statusColor() {
        switch (status) {
          case 'accepted':
            return Colors.green[300]!;
          case 'pending':
            return const Color.fromARGB(255, 255, 127, 77);
          case 'rejected':
            return Colors.red[300]!;
          default:
            return Colors.grey[300]!;
        }
      }

      IconData statusIcon() {
        switch (status) {
          case 'accepted':
            return Icons.check_circle;
          case 'pending':
            return Icons.access_time;
          case 'rejected':
            return Icons.cancel;
          default:
            return Icons.help;
        }
      }

      Widget buildStatusProgressBar() {
        final steps = ['pending', 'accepted', 'delivered'];
        int currentStep = steps.indexOf(status);

        bool isRejected = status == 'rejected';

        Color stepColor(int index) {
          if (isRejected) {
            return Colors.redAccent;
          }
          if (index < currentStep) {
            return Colors.green;
          } else if (index == currentStep) {
            return Colors.orange;
          } else {
            return Colors.grey[300]!;
          }
        }

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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: stepColor(i),
                              shape: BoxShape.circle,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: stepColor(i).withOpacity(0.6),
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
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: stepColor(i),
                      ),
                      child: Text(steps[i].toUpperCase()),
                    ),
                  ],
                ),
                if (i != steps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                        child: const Text('REJECTED'),
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
              letterSpacing: 0.3,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ordered At Card
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(0, 33, 33, 33),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        255,
                        255,
                        255,
                      ).withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$formattedDate',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Animated status progress bar here
              buildStatusProgressBar(),
              const SizedBox(height: 10),
              Text(
                'Ordered Items',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              // Items list
              ...items.map((item) {
                final itemMap = item as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.inventory_2,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    title: Text(
                      itemMap['itemId'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        color: const Color.fromARGB(255, 22, 22, 22),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Quantity: ${itemMap['quantity'] ?? ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color.fromARGB(179, 43, 43, 43),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              // Status Card
              // Container(
              //   decoration: BoxDecoration(
              //     color: statusColor(),
              //     borderRadius: BorderRadius.circular(16),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.1),
              //         offset: const Offset(0, 4),
              //         blurRadius: 8,
              //       ),
              //     ],
              //   ),
              //   padding: const EdgeInsets.all(16),
              //   child: Row(
              //     children: [
              //       Icon(statusIcon(), color: Colors.white),
              //       const SizedBox(width: 10),
              //       Text(
              //         'Status: ${status.toUpperCase()}',
              //         style: GoogleFonts.poppins(
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //           color: Colors.white,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),

              // Conditional UI based on status
              //   if (status == 'delivered')
              //     Center(
              //       child: ElevatedButton.icon(
              //         icon: const Icon(Icons.done_all),
              //         label: const Text("Confirm Delivery"),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.teal,
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 24,
              //             vertical: 12,
              //           ),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20),
              //           ),
              //         ),
              //         onPressed: () async {
              //           try {
              //             final firestore = FirebaseFirestore.instance;

              //             // Save to history
              //             await firestore.collection('history').add({
              //               ...orderData,
              //               'confirmedAt': Timestamp.now(),
              //             });

              //             // Delete from orders
              //             await widget.orderDoc.reference.delete();

              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(
              //                 content: Text(
              //                   "Order confirmed and removed from list!",
              //                 ),
              //               ),
              //             );

              //             Navigator.pop(context);
              //           } catch (e) {
              //             ScaffoldMessenger.of(
              //               context,
              //             ).showSnackBar(SnackBar(content: Text("Error: $e")));
              //           }
              //         },
              //       ),
              //     )
              //   else if (status == 'rejected')
              //     Center(
              //       child: ElevatedButton.icon(
              //         icon: const Icon(Icons.edit),
              //         label: const Text("Edit and Reorder"),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: Colors.redAccent,
              //           padding: const EdgeInsets.symmetric(
              //             horizontal: 24,
              //             vertical: 12,
              //           ),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20),
              //           ),
              //         ),
              //         onPressed: () {
              //           ScaffoldMessenger.of(context).showSnackBar(
              //             const SnackBar(
              //               content: Text("Implement reorder/edit logic here."),
              //             ),
              //           );
              //         },
              //       ),
              //     )
              //   else if (status == 'pending')
              //     Center(
              //       child: Text(
              //         'Waiting for supplier to accept/reject...',
              //         style: GoogleFonts.poppins(
              //           color: Colors.orange[800],
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     )
              //   else if (status == 'accepted')
              //     Center(
              //       child: Text(
              //         'Order has been accepted!',
              //         style: GoogleFonts.poppins(
              //           color: Colors.green[800],
              //           fontSize: 16,
              //           fontWeight: FontWeight.w600,
              //         ),
              //       ),
              //     ),
            ],
          ),
        ),
      );
    }
  }
