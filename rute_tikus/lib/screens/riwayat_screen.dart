import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rute_tikus/screens/detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final borderColor = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Aktivitas',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: currentUserId == null
          ? Center(
              child: Text(
                'Silakan login terlebih dahulu.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('postingan')
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: theme.dividerColor),
                        const SizedBox(height: 12),
                        Text(
                          'Anda belum pernah membuat laporan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
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
                    final type = data['type'] as String?;
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
                                'jenis': data['type'], 
                                'estimasiHari': data['durationDays'], 
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        shadowColor: isDark ? Colors.black54 : Colors.black12,
                        color: theme.cardColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: data['image'] != null
                                  ? Image.memory(
                                      base64Decode(data['image']),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 180,
                                      color: isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F2),
                                      child: Center(
                                        child: Icon(Icons.image_outlined, size: 50, color: theme.dividerColor),
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          type ?? 'Lainnya',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (data['durationDays'] != null)
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 12, color: theme.dividerColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data['durationDays']} hari',
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.dividerColor),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data['title'] ?? 'Tanpa Judul',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      data['description'],
                                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_outlined, size: 14, color: accent),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          data['locationName'] ?? '-',
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time, size: 14, color: theme.dividerColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}