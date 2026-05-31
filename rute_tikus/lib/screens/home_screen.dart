import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rute_tikus/screens/post_screen.dart';
import 'package:rute_tikus/screens/detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rute Tikus',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('postingan')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada data penutupan jalan.',
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Tap + untuk tambah laporan.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              return _BlockadeCard(data: data, docId: docId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBlockadePostScreen()),
          );
        },
        backgroundColor: const Color(0xFF000080),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
class _BlockadeCard extends StatelessWidget {
  const _BlockadeCard({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  Color _typeColor(String? type) {
    switch (type) {
      case 'Tenda Hajatan':
        return const Color(0xFFFF9800);
      case 'Penutupan Jalan':
        return const Color(0xFFF44336);
      case 'Pekerjaan Jalan':
        return const Color(0xFFFFC107);
      case 'Pasar Dadakan':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String?;
    final color = _typeColor(type);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              blockadeId: docId,
              data: {
                'judul': data['title'],
                'deskripsi': data['description'],
                'lokasi': data['locationName'],
                'jam': '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}',
                'tempat_tujuan': data['nearestDest'],
                'rute_alternatif': data['altRoute'],
                'fotoBase64': data['image'],
                'latitude': data['latitude'],
                'longitude': data['longitude'],
                'type': data['type'],
                'durationDays': data['durationDays'],
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: data['image'] != null
                  ? Image.memory(
                      base64Decode(data['image']),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                        child:
                            Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text(
                          type ?? 'Lainnya',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      if (data['durationDays'] != null)
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              '${data['durationDays']} hari',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    data['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),


                  if (data['description'] != null &&
                      data['description'].toString().isNotEmpty)
                    Text(
                      data['description'],
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          data['locationName'] ?? '-',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  if (data['altRoute'] != null &&
                      data['altRoute'].toString().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.alt_route,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            data['altRoute'],
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  Text(
                    'Dilaporkan oleh: ${data['fullName'] ?? 'Anonim'}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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