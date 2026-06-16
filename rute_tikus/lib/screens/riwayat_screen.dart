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
                    
                    // Menyelaraskan fallback key (Bahasa Indonesia ?? Bahasa Inggris)
                    final String? fotoBase64 = data['fotoBase64'] ?? data['image'];
                    final String judul = data['judul'] ?? data['title'] ?? 'Tanpa Judul';
                    final String? deskripsi = data['deskripsi'] ?? data['description'];
                    final String jenis = data['jenis'] ?? data['type'] ?? 'Lainnya';
                    final String lokasi = data['lokasi'] ?? data['locationName'] ?? '-';
                    final dynamic estimasiHari = data['estimasiHari'] ?? data['durationDays'];
                    final String jamOperasional = data['jam'] ?? '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              blockadeId: docId,
                              data: {
                                'judul': judul,
                                'deskripsi': deskripsi,
                                'lokasi': lokasi,
                                'jam': jamOperasional,
                                'tempat_tujuan': data['tempat_tujuan'] ?? data['nearestDest'],
                                'rute_alternatif': data['rute_alternatif'] ?? data['altRoute'],
                                'fotoBase64': fotoBase64,
                                'latitude': data['latitude'],
                                'longitude': data['longitude'],
                                'jenis': jenis, 
                                'estimasiHari': estimasiHari, 
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
                              child: fotoBase64 != null
                                  ? Image.memory(
                                      base64Decode(fotoBase64),
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
                                          jenis,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (estimasiHari != null)
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 12, color: theme.dividerColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$estimasiHari hari',
                                              style: theme.textTheme.bodySmall?.copyWith(color: theme.dividerColor),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    judul,
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (deskripsi != null && deskripsi.toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      deskripsi,
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
                                          lokasi,
                                          style: theme.textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time, size: 14, color: theme.dividerColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        jamOperasional,
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