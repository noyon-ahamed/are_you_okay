import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/api/earthquake_service.dart';

class EarthquakeScreen extends ConsumerStatefulWidget {
  const EarthquakeScreen({super.key});

  @override
  ConsumerState<EarthquakeScreen> createState() => _EarthquakeScreenState();
}

class _EarthquakeScreenState extends ConsumerState<EarthquakeScreen> {
  late Future<List<dynamic>> _earthquakesFuture;

  @override
  void initState() {
    super.initState();
    _loadEarthquakes();
  }

  void _loadEarthquakes() {
    _earthquakesFuture = ref.read(earthquakeServiceProvider).getRecentEarthquakes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ভূমিকম্প সতর্কতা'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadEarthquakes();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _earthquakesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                  const SizedBox(height: 16),
                  Text('তথ্য লোড করা যায়নি: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(_loadEarthquakes),
                    child: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }

          final earthquakes = snapshot.data ?? [];
          
          if (earthquakes.isEmpty) {
            return const Center(
              child: Text('কোনো সাম্প্রতিক ভূমিকম্পের তথ্য নেই'),
            );
          }

          return ListView.builder(
            itemCount: earthquakes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final quake = earthquakes[index];
              final magnitude = double.tryParse(quake['magnitude'].toString()) ?? 0.0;
              final date = DateTime.tryParse(quake['time'].toString()) ?? DateTime.now();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForMagnitude(magnitude),
                    child: Text(
                      magnitude.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    quake['place'] ?? 'অজানা স্থান',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(date.toLocal()),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getColorForMagnitude(double mag) {
    if (mag >= 7.0) return const Color(0xFFD32F2F); // Red
    if (mag >= 5.0) return const Color(0xFFF57C00); // Orange
    if (mag >= 3.0) return const Color(0xFFFBC02D); // Yellow
    return const Color(0xFF388E3C); // Green
  }
}
