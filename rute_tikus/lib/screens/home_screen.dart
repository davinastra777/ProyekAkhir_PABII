import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rute_tikus/screens/post_screen.dart';
import 'package:rute_tikus/screens/profile_screen.dart';
import 'package:rute_tikus/screens/detail_screen.dart';

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
    final cardBackground = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rute Tikus',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Cari nama jalan atau judul laporan...',
                hintStyle: theme.textTheme.bodySmall,
                prefixIcon: Icon(Icons.search_outlined, color: accent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: borderColor),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
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
                        Icon(Icons.map_outlined, size: 64, color: theme.dividerColor),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada data penutupan jalan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + untuk tambah laporan.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.dividerColor),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final lokasi = (data['locationName'] ?? '').toString().toLowerCase();
                  final type = (data['type'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || lokasi.contains(_searchQuery) || type.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_outlined, size: 52, color: theme.dividerColor),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada laporan untuk "$_searchQuery"',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
                      ],
                    ),
                  );
                }

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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBlockadePostScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _BlockadeCard extends StatelessWidget {
  const _BlockadeCard({required this.data, required this.docId});
  final Map<String, dynamic> data;
  final String docId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
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
                  if (data['altRoute'] != null && data['altRoute'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.alt_route, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['altRoute'],
                            style: theme.textTheme.bodySmall?.copyWith(color: accent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Dilaporkan oleh: ${data['fullName'] ?? 'Anonim'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.dividerColor),
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
