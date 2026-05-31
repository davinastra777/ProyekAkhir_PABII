import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disimpan',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: currentUserId == null
          ? const Center(child: Text('Silakan login terlebih dahulu.'))
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
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Belum ada postingan yang difavoritkan.',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)),
                      ],
                    ),
                  );
                }

                final favoriteList = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: favoriteList.length,
                  itemBuilder: (context, index) {
                    final data =
                        favoriteList[index].data() as Map<String, dynamic>;
                    final favDocId = favoriteList[index].id;
                    final postinganId = data['postinganId'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            child: data['fotoBase64'] != null
                                ? Image.memory(
                                    base64Decode(data['fotoBase64']),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 160,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.image,
                                          size: 50, color: Colors.grey),
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
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 13, color: Colors.redAccent),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        data['lokasi'] ?? '-',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 13, color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Text(
                                      data['jam'] ?? '-',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),

                                if (data['rute_alternatif'] != null &&
                                    data['rute_alternatif']
                                        .toString()
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.alt_route,
                                            size: 13, color: Colors.green),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            data['rute_alternatif'],
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.green),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('favorites')
                                        .doc(favDocId)
                                        .delete();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Dihapus dari favorit')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.favorite,
                                      color: Colors.red, size: 18),
                                  label: const Text('Hapus',
                                      style: TextStyle(color: Colors.red)),
                                ),

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
                                  icon: const Icon(Icons.arrow_forward,
                                      size: 16),
                                  label: const Text('Lihat Detail'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF000080),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
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