import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rute_tikus/screens/detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
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
          'Disimpan',
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
                  .collection('favorites')
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
                        Icon(Icons.favorite_border, size: 64, color: theme.dividerColor),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada postingan yang difavoritkan.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.dividerColor),
                        ),
                      ],
                    ),
                  );
                }

                final favoriteList = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: favoriteList.length,
                  itemBuilder: (context, index) {
                    final data = favoriteList[index].data() as Map<String, dynamic>;
                    final favDocId = favoriteList[index].id;
                    final postinganId = data['postinganId'] ?? '';

                    return Card(
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
                            child: data['fotoBase64'] != null
                                ? Image.memory(
                                    base64Decode(data['fotoBase64']),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 160,
                                    color: isDark ? const Color(0xFF111111) : const Color(0xFFF2F2F2),
                                    child: Center(
                                      child: Icon(Icons.image_outlined, size: 50, color: theme.dividerColor),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['judul'] ?? 'Tanpa Judul',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 13, color: accent),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        data['lokasi'] ?? '-',
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 13, color: theme.dividerColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      data['jam'] ?? '-',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (data['rute_alternatif'] != null && data['rute_alternatif'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.alt_route, size: 13, color: accent),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          data['rute_alternatif'],
                                          style: theme.textTheme.bodySmall?.copyWith(color: accent),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('favorites').doc(favDocId).delete();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Dihapus dari favorit')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                                  label: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DetailScreen(
                                          blockadeId: postinganId,
                                          data: data,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.arrow_forward, size: 16),
                                  label: const Text('Lihat Detail'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}