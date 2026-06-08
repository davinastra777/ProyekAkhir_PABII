import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rute_tikus/screens/post_screen.dart';
import 'package:rute_tikus/screens/profile_screen.dart';
import 'package:rute_tikus/screens/detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum StatusFilter { semua, belumMulai, berlangsung, selesai }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StatusFilter _filter = StatusFilter.semua;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  StatusFilter _getStatus(Map<String, dynamic> d) {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(d['startDate'] ?? d['tanggalMulai']);
      final end = DateTime.parse(d['endDate'] ?? d['tanggalSelesai']);
      if (now.isBefore(start)) return StatusFilter.belumMulai;
      if (now.isAfter(end)) return StatusFilter.selesai;
      return StatusFilter.berlangsung;
    } catch (_) {
      return StatusFilter.semua;
    }
  }

  List<QueryDocumentSnapshot> _filtered(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final hit =
            (d['title'] ?? d['judul'] ?? '').toString().toLowerCase().contains(q) ||
            (d['locationName'] ?? d['lokasi'] ?? '').toString().toLowerCase().contains(q) ||
            (d['type'] ?? d['jenis'] ?? '').toString().toLowerCase().contains(q);
        if (!hit) return false;
      }
      if (_filter != StatusFilter.semua) return _getStatus(d) == _filter;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;

    // Filter definitions: (enum, label, color, icon)
    final filters = [
      (StatusFilter.semua, 'Semua', accent, Icons.list_rounded),
      (StatusFilter.belumMulai, 'Belum Mulai', Colors.blue, Icons.schedule_rounded),
      (StatusFilter.berlangsung, 'Berlangsung', Colors.orange, Icons.warning_amber_rounded),
      (StatusFilter.selesai, 'Selesai', Colors.green, Icons.check_circle_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Row(children: [
          Icon(Icons.map_rounded, color: accent, size: 26),
          const SizedBox(width: 8),
          Text('Rute Tikus',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ]),
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
      body: Column(children: [
        // ── Search + Filter ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari jalan, acara, lokasi...',
                prefixIcon: Icon(Icons.search, color: accent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        }),
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            const SizedBox(height: 10),
            // Filter chips dengan icon
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((f) {
                  final selected = _filter == f.$1;
                  final color = f.$3;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color : theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? color : theme.dividerColor,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(f.$4,
                              size: 14,
                              color: selected ? Colors.white : color),
                          const SizedBox(width: 5),
                          Text(f.$2,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                              )),
                        ]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),

        // ── List ──
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('postingan')
                .orderBy('createdAt', descending: true)
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
                      Icon(Icons.map_outlined, size: 56, color: theme.dividerColor),
                      const SizedBox(height: 12),
                      Text('Belum ada laporan.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              final docs = _filtered(snapshot.data!.docs);
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 56, color: theme.dividerColor),
                      const SizedBox(height: 12),
                      Text('Tidak ada laporan yang cocok.',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 80),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _BlockadeCard(data: d, docId: docs[i].id);
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddBlockadePostScreen())),
        backgroundColor: accent,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Tambah',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD
// ─────────────────────────────────────────────────────────────
class _BlockadeCard extends StatelessWidget {
  const _BlockadeCard({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  String _fmtTanggal(String? a, String? b) {
    if (a == null || b == null) return '-';
    try {
      final s = DateFormat('dd MMM').format(DateTime.parse(a));
      final e = DateFormat('dd MMM yyyy').format(DateTime.parse(b));
      return '$s - $e';
    } catch (_) {
      return '-';
    }
  }

  ({Color color, String label, IconData icon}) _status() {
    try {
      final now = DateTime.now();
      final start = DateTime.parse(data['startDate'] ?? data['tanggalMulai']);
      final end = DateTime.parse(data['endDate'] ?? data['tanggalSelesai']);
      if (now.isBefore(start)) return (color: Colors.blue, label: 'Belum Mulai', icon: Icons.schedule_rounded);
      if (now.isAfter(end)) return (color: Colors.green, label: 'Selesai', icon: Icons.check_circle_rounded);
      return (color: Colors.orange, label: 'Berlangsung', icon: Icons.warning_amber_rounded);
    } catch (_) {
      return (color: Colors.grey, label: '-', icon: Icons.help_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final img = data['image'] ?? data['fotoBase64'];
    final title = data['title'] ?? data['judul'] ?? 'Tanpa Judul';
    final loc = data['locationName'] ?? data['lokasi'] ?? '-';
    final type = data['type'] ?? data['jenis'] ?? 'Lainnya';
    final jam = data['jam'] ?? '${data['openTime'] ?? ''} - ${data['closeTime'] ?? ''}';
    final tanggal = _fmtTanggal(
        data['startDate'] ?? data['tanggalMulai'],
        data['endDate'] ?? data['tanggalSelesai']);
    final altRoute = data['altRoute'] ?? data['rute_alternatif'] ?? '';
    final reporter = data['fullName'] ?? 'Anonim';
    final st = _status();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailScreen(
            blockadeId: docId,
            data: {
              'judul': title,
              'deskripsi': data['description'] ?? data['deskripsi'],
              'lokasi': loc,
              'jam': jam,
              'tempat_tujuan': data['nearestDest'] ?? data['tempat_tujuan'],
              'rute_alternatif': altRoute,
              'fotoBase64': img,
              'latitude': data['latitude'],
              'longitude': data['longitude'],
              'jenis': type,
              'estimasiHari': data['durationDays'] ?? data['estimasiHari'],
            },
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Foto ──
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: img != null
                  ? Image.memory(base64Decode(img),
                      height: 170, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 170,
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.image_outlined, size: 40, color: Colors.grey))),
            ),
            // Gradient bawah foto
            Positioned(
              bottom: 0, left: 0, right: 0, height: 70,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Tipe chip (kiri atas)
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(20)),
                child: Text(type,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            // Status chip (kanan atas) dengan icon
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: st.color, borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(st.icon, size: 11, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(st.label,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),

          // ── Info ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Judul
              Text(title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),

              const SizedBox(height: 10),

              // Lokasi
              Row(children: [
                Icon(Icons.location_on_rounded, size: 16, color: accent),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(loc,
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),

              const SizedBox(height: 6),

              // Tanggal & jam
              Row(children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: theme.dividerColor),
                const SizedBox(width: 5),
                Text(tanggal, style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded, size: 13, color: theme.dividerColor),
                const SizedBox(width: 5),
                Text(jam, style: theme.textTheme.bodySmall),
              ]),

              // Rute alternatif (kalau ada)
              if (altRoute.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.alt_route, size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(altRoute,
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              ],

              const SizedBox(height: 10),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.4)),
              const SizedBox(height: 10),

              // Reporter
              Row(children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: accent.withOpacity(0.15),
                  child: Icon(Icons.person, size: 12, color: accent),
                ),
                const SizedBox(width: 6),
                Text('Dilaporkan oleh: ',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                Expanded(
                  child: Text(reporter,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}