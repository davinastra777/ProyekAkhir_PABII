import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _mapToDetailData(Map<String, dynamic> data) {
    return {
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
    };
  }

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
    const primary = Color(0xFF000080);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Informasi Rute',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Cari nama jalan atau judul laporan...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFF000080)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
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
                  return const Center(
                    child: Text('Belum ada data laporan.'),
                  );
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (_searchQuery.isEmpty) return true;
                  final title =
                      (data['title'] ?? '').toString().toLowerCase();
                  final lokasi =
                      (data['locationName'] ?? '').toString().toLowerCase();
                  final type =
                      (data['type'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) ||
                      lokasi.contains(_searchQuery) ||
                      type.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 52, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada laporan untuk "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data =
                        filtered[index].data() as Map<String, dynamic>;
                    final type = data['type'] as String?;
                    final color = _typeColor(type);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.15),
                          child: Icon(Icons.location_on, color: color),
                        ),
                        title: Text(
                          data['title'] ?? 'Tanpa Judul',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.signpost,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    data['locationName'] ?? '-',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                type ?? 'Lainnya',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_forward_ios, size: 14),
                            if (data['durationDays'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${data['durationDays']}h',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                              blockadeId: filtered[index].id,
                                data: _mapToDetailData(data),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}