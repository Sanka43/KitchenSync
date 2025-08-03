import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPage extends StatefulWidget {
  final String hotelId;
  final String hotelName;

  const ReportPage({super.key, required this.hotelId, required this.hotelName});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String selectedMode = 'Day'; // "Day" or "Month"
  DateTime? selectedDate = DateTime.now();
  DateTime? selectedMonth = DateTime.now();

  bool loading = false;
  List<Map<String, dynamic>> filteredReports = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => loading = true);
    try {
      DateTime startDate;
      DateTime endDate;

      if (selectedMode == 'Month' && selectedMonth != null) {
        startDate = DateTime(selectedMonth!.year, selectedMonth!.month, 1);
        endDate = DateTime(
          selectedMonth!.year,
          selectedMonth!.month + 1,
          0,
          23,
          59,
          59,
        );
      } else if (selectedMode == 'Day' && selectedDate != null) {
        startDate = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
        );
        endDate = DateTime(
          selectedDate!.year,
          selectedDate!.month,
          selectedDate!.day,
          23,
          59,
          59,
        );
      } else {
        setState(() {
          filteredReports = [];
          loading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('history')
          .where('hotelId', isEqualTo: widget.hotelId)
          .where(
            'confirmedAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'confirmedAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('confirmedAt', descending: true)
          .get();

      filteredReports = snapshot.docs.map((doc) {
        final data = doc.data();
        final items = data['items'] ?? [];
        int totalQty = items.fold(
          0,
          (sum, item) => sum + int.tryParse(item['quantity'] ?? '0') ?? 0,
        );
        return {
          'date': (data['confirmedAt'] as Timestamp).toDate(),
          'status': data['status'],
          'note': data['note'] ?? '',
          'itemCount': items.length,
          'totalQuantity': totalQty,
        };
      }).toList();
    } catch (e) {
      print('Error loading reports: $e');
    }
    setState(() => loading = false);
  }

  Future<void> _generateAndDownloadPdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd');

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            '${widget.hotelName} - ${selectedMode.toUpperCase()} REPORT',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: ['Date', 'Status', 'Items', 'Qty', 'Note'],
            data: filteredReports.map((e) {
              return [
                dateFormat.format(e['date']),
                e['status'],
                e['itemCount'].toString(),
                e['totalQuantity'].toString(),
                e['note'],
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.hotelName}_${selectedMode.toLowerCase()}_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Text(
          'Generate Report',
          style: GoogleFonts.poppins(
            color: const Color(0xFF151640),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 40, // fixed height for dropdown container
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E6EBC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedMode,
                              items: ['Day', 'Month'].map((mode) {
                                return DropdownMenuItem(
                                  value: mode,
                                  child: Text(
                                    mode,
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedMode = value;
                                  });
                                  _loadReport();
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                              isDense:
                                  true, // reduces vertical padding inside dropdown
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 40, // match the dropdown height here
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedMode == 'Month'
                                  ? (selectedMonth ?? DateTime.now())
                                  : (selectedDate ?? DateTime.now()),
                              firstDate: DateTime(2022),
                              lastDate: DateTime(2100),
                              helpText: selectedMode == 'Month'
                                  ? 'Select Month'
                                  : 'Select Date',
                            );
                            if (picked != null) {
                              setState(() {
                                if (selectedMode == 'Month') {
                                  selectedMonth = picked;
                                } else {
                                  selectedDate = picked;
                                }
                              });
                              _loadReport();
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            selectedMode == 'Month'
                                ? DateFormat(
                                    'MMMM yyyy',
                                  ).format(selectedMonth ?? DateTime.now())
                                : DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(selectedDate ?? DateTime.now()),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6EBC),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(
                              0,
                              40,
                            ), // make sure height stays 40
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Expanded(
                    child: filteredReports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No report data found.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredReports.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(report['date']),
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF151640),
                                            fontSize: 16,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            report['status']
                                                .toString()
                                                .toUpperCase(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${report['itemCount']} items • Qty: ${report['totalQuantity']}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    if ((report['note'] ?? '')
                                        .toString()
                                        .trim()
                                        .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          'Note: ${report['note']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _generateAndDownloadPdf,
                        icon: const Icon(Icons.download),
                        label: Text(
                          'Download PDF',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E6EBC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
