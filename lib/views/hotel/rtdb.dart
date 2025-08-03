import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class AHotelDashboard extends StatefulWidget {
  @override
  _AHotelDashboardState createState() => _AHotelDashboardState();
}

class _AHotelDashboardState extends State<AHotelDashboard> {
  Map<String, double> weightsData = {};
  final DatabaseReference weightRef = FirebaseDatabase.instance.ref().child(
    'weights',
  );

  Map<String, double> maxScales = {
    'Chill_Powder': 2.0,
    'Corn_Flour': 1.5,
    'Rice': 5.0,
    'Suger': 2.0,
    'oil_liter': 6.0,
  };

  List<Color> lineColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    loadWeightsData();
  }

  void loadWeightsData() {
    weightRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final rawMap = Map<String, dynamic>.from(data);
        setState(() {
          weightsData = rawMap.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        });
        print("✅ weightsData loaded: \$weightsData");
      } else {
        print("⚠️ No valid data at /weights");
      }
    });
  }

  Widget _buildWeightLineChart() {
    final dataToShow = weightsData.isNotEmpty
        ? weightsData
        : {
            'Chill_Powder': 0,
            'Corn_Flour': 0,
            'Rice': 0,
            'Suger': 0,
            'oil_liter': 0,
          };

    final Map<String, double> percentages = {};
    dataToShow.forEach((key, value) {
      final max = maxScales[key] ?? 1;
      final pct = ((value / max) * 100).clamp(0, 100).toDouble();
      percentages[key] = pct;
    });

    final itemCount = percentages.length;
    final keys = percentages.keys.toList();

    List<FlSpot> spots = [];
    for (int i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), percentages[keys[i]]!));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weight Levels (%)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.6,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 110,
                minX: 0,
                maxX: itemCount > 0 ? (itemCount - 1).toDouble() : 1,
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= keys.length)
                          return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            keys[index],
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) =>
                          Text('\${value.toInt()}%'),
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: percentages.entries.map((entry) {
              final color = Colors.blue;
              final isLow = entry.value < 25;
              return Chip(
                backgroundColor: color.withOpacity(0.15),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\${entry.key}: \${entry.value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isLow) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotel Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF1F3F6),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [_buildWeightLineChart(), const SizedBox(height: 24)],
      ),
    );
  }
}
