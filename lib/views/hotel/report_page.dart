import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String filterType = 'day';
  DateTimeRange? customRange;
  bool isLoading = false;
  List<DocumentSnapshot> reportData = [];

  Future<void> fetchReport() async {
    setState(() => isLoading = true);
    final now = DateTime.now();
    DateTime start, end;

    if (filterType == 'day') {
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
    } else if (filterType == 'month') {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
    } else if (filterType == 'year') {
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year + 1, 1, 1);
    } else if (filterType == 'custom' && customRange != null) {
      start = customRange!.start;
      end = customRange!.end.add(const Duration(days: 1));
    } else {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('history')
        .where('confirmedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('confirmedAt', isLessThan: Timestamp.fromDate(end))
        .get();

    reportData = snapshot.docs;
    setState(() => isLoading = false);
  }

  Future<Uint8List> generatePDF() async {
    final pdf = pw.Document();

    for (var doc in reportData) {
      final data = doc.data() as Map<String, dynamic>;
      final hotelSnapshot = await FirebaseFirestore.instance
          .collection('hotels')
          .doc(data['hotelId'])
          .get();
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .doc(data['shopId'])
          .get();

      final hotelName = hotelSnapshot.data()?['hotelName'] ?? 'Unknown Hotel';
      final shopName = shopSnapshot.data()?['name'] ?? 'Unknown Shop';
      final confirmedAt = (data['confirmedAt'] as Timestamp).toDate();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(confirmedAt);
      final items = List<Map<String, dynamic>>.from(data['items']);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Delivery Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Hotel: $hotelName'),
                pw.Text('Shop: $shopName'),
                pw.Text('Status: ${data['status']}'),
                pw.Text('Confirmed At: $formattedDate'),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  headers: ['Item ID', 'Quantity'],
                  data: items
                      .map((item) => [item['itemId'], item['quantity']])
                      .toList(),
                ),
                pw.Divider(),
              ],
            ),
          ),
        ),
      );
    }

    return pdf.save();
  }

  void showOrderDetails(Map<String, dynamic> data) async {
    final hotelSnapshot = await FirebaseFirestore.instance
        .collection('hotels')
        .doc(data['hotelId'])
        .get();
    final shopSnapshot = await FirebaseFirestore.instance
        .collection('shops')
        .doc(data['shopId'])
        .get();
    final hotelName = hotelSnapshot.data()?['hotelName'] ?? 'Unknown Hotel';
    final shopName = shopSnapshot.data()?['name'] ?? 'Unknown Shop';
    final items = List<Map<String, dynamic>>.from(data['items']);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(
        0.3,
      ), // blurred semi-transparent background
      builder: (context) => Dialog(
        backgroundColor:
            Colors.transparent, // transparent to show blurred content
        insetPadding: const EdgeInsets.all(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Details',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF151640),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hotel: $hotelName',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF151640),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Shop: $shopName',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF151640),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Divider(color: Colors.grey.shade700),
                ...items.map(
                  (item) => Text(
                    '• ${item['itemId']} - Qty: ${item['quantity']}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF151640),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${data['status']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF151640),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      backgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF151640),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        title: Text(
          'Generate Report',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF151640),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: filterType,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(color: Colors.black),
              dropdownColor: Colors.white,
              elevation: 4,
              items: const [
                DropdownMenuItem(value: 'day', child: Text('Today')),
                DropdownMenuItem(value: 'month', child: Text('This Month')),
                DropdownMenuItem(value: 'year', child: Text('This Year')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
              ],
              onChanged: (val) async {
                setState(() => filterType = val!);
                if (val == 'custom') {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 2),
                    lastDate: DateTime(now.year + 1),
                    initialDateRange:
                        customRange ??
                        DateTimeRange(
                          start: now.subtract(const Duration(days: 7)),
                          end: now,
                        ),
                  );
                  if (picked != null) {
                    setState(() => customRange = picked);
                  }
                }
              },
            ),
            if (filterType == 'custom' && customRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${DateFormat('yyyy-MM-dd').format(customRange!.start)} → ${DateFormat('yyyy-MM-dd').format(customRange!.end)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: fetchReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(
                'Fetch Report',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (!isLoading && reportData.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: reportData.length,
                        itemBuilder: (context, index) {
                          final data =
                              reportData[index].data() as Map<String, dynamic>;
                          final timestamp = (data['confirmedAt'] as Timestamp)
                              .toDate();
                          return GestureDetector(
                            onTap: () => showOrderDetails(data),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Status: ${data['status']}",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Confirmed: ${DateFormat('yyyy-MM-dd HH:mm').format(timestamp)}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Download PDF',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () async {
                        final pdfData = await generatePDF();
                        await Printing.sharePdf(
                          bytes: pdfData,
                          filename: 'report.pdf',
                        );
                      },
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
