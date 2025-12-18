import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

// Coffee-themed colors from main.dart
const Color primaryColor = Color(0xFF6D4C41);
const Color primaryColorDark = Color(0xFF4E342E);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardColor = Colors.white;
const Color accentColor = Color(0xFFA1887F);

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({super.key});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('predictions');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Predictions',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: backgroundColor,
      body: StreamBuilder(
        stream: _dbRef.orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            final predictions = data.entries.map((e) {
              final prediction = e.value as Map<dynamic, dynamic>;
              return {
                'key': e.key,
                'prediction': prediction['prediction'],
                'confidence': prediction['confidence'],
                'timestamp': prediction['timestamp'],
              };
            }).toList();
            // Sort predictions by timestamp in descending order
            predictions.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

            return ListView.builder(
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final prediction = predictions[index];
                final confidence = (prediction['confidence'] * 100).toStringAsFixed(2);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      prediction['prediction'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: primaryColorDark,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Confidence: $confidence%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: ${prediction['timestamp']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No predictions found.'));
          } else {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
        },
      ),
    );
  }
}
