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
        title: const Text('Disimpan'),
        backgroundColor: const Color.fromARGB(255, 1, 1, 129),
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
                  return const Center(child: Text('Belum ada postingan yang difavoritkan.'));
                }

                final favoriteList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: favoriteList.length,
                  itemBuilder: (context, index) {
                    var data = favoriteList[index].data() as Map<String, dynamic>;
                    String docId = favoriteList[index].id;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          data['fotoBase64'] != null
                              ? Image.memory(
                                  base64Decode(data['fotoBase64']),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 150,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 50),
                                ),
                          
                          ListTile(
                            title: Text(
                              data['judul'] ?? 'Tanpa Judul',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Lokasi: ${data['lokasi'] ?? '-'}\nWaktu: ${data['jam'] ?? '-'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.favorite, color: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('favorites').doc(docId).delete();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Dihapus dari favorit')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetailScreen(data: data)),
                              );
                            },
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