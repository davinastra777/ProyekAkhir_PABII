import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rute_tikus/screens/post_screen.dart';
import 'package:rute_tikus/screens/profile_screen.dart';
import 'package:rute_tikus/screens/detail_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final borderColor = theme.dividerColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(Icons.map_rounded, color: accent, size: 28),
            const SizedBox(width: 8),
            Text(
              'Rute Tikus',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                  : null,
              builder: (context, snapshot) {
                String? base64Image;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  base64Image = data['fotoProfil'];
                }

                return IconButton(
                  icon: CircleAvatar(
                    radius: 18,
                    backgroundColor: accent.withOpacity(0.1),
                    backgroundImage: base64Image != null && base64Image.isNotEmpty
                        ? MemoryImage(base64Decode(base64Image))
                        : null,
                    child: base64Image == null || base64Image.isEmpty
                        ? Icon(Icons.person, color: accent, size: 22)
                        : null,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cari Rute Alternatif',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Cari jalan, acara, atau lokasi...',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: accent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.cancel_rounded, color: borderColor, size: 20),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('postingan')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Terjadi kesalahan memuat data.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.map_outlined, size: 64, color: accent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Jalanan sedang aman!',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada laporan penutupan jalan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? data['judul'] ?? '').toString().toLowerCase();
                  final lokasi = (data['locationName'] ?? data['lokasi'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? data['jenis'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || lokasi.contains(_searchQuery) || type.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil untuk "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _BlockadeCard(data: data, docId: docId);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBlockadePostScreen()),
          );
        },
        backgroundColor: accent,
        elevation: 4,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _BlockadeCard extends StatelessWidget {
  const _BlockadeCard({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  String _formatTanggalCerdas(String? startDateIso, String? endDateIso) {
    if (startDateIso == null || endDateIso == null) return '-';
    try {
      final start = DateTime.parse(startDateIso);
      final end = DateTime.parse(endDateIso);
      
      final startStr = DateFormat('dd MMM').format(start);
      final endStr = DateFormat('dd MMM yyyy').format(end);

      if (start.day == end.day && start.month == end.month && start.year == end.year) {
        return endStr;
      }
      return '$startStr - $endStr';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final type = data['type'] ?? data['jenis'] ?? 'Lainnya';
    final title = data['title'] ?? data['judul'] ?? 'Tanpa Judul';
    final location = data['locationName'] ?? data['lokasi'] ?? '-';
    final imageBase64 = data['image'] ?? data['fotoBase64'];
    final timeStr = data['jam'] ?? '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}';
    final reporter = data['fullName'] ?? 'Anonim';
    final tanggalAktif = _formatTanggalCerdas(data['startDate'] ?? data['tanggalMulai'], data['endDate'] ?? data['tanggalSelesai']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailScreen(
              blockadeId: docId,
              data: {
                'judul': title,
                'deskripsi': data['description'] ?? data['deskripsi'],
                'lokasi': location,
                'jam': timeStr,
                'tempat_tujuan': data['nearestDest'] ?? data['tempat_tujuan'],
                'rute_alternatif': data['altRoute'] ?? data['rute_alternatif'],
                'fotoBase64': imageBase64,
                'latitude': data['latitude'],
                'longitude': data['longitude'],
                'jenis': type,
                'estimasiHari': data['durationDays'] ?? data['estimasiHari'],
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: imageBase64 != null
                      ? Image.memory(
                          base64Decode(imageBase64),
                          height: 170,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 170,
                          color: isDark ? const Color(0xFF222222) : Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_outlined, size: 50, color: theme.dividerColor),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_rounded, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: theme.dividerColor),
                      const SizedBox(width: 6),
                      Text(
                        tanggalAktif,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_rounded, size: 16, color: theme.dividerColor),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: accent.withOpacity(0.2),
                        child: Icon(Icons.person, size: 12, color: accent),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dilaporkan oleh: ',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      Text(
                        reporter,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
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
  }
}