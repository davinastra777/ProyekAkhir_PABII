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
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Informasi Rute'),
        backgroundColor: const Color.fromARGB(255, 1, 1, 129),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari nama jalan atau judul laporan...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('postingan').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada data laporan.'));
                }

                final allDocs = snapshot.data!.docs;
                
                List<DocumentSnapshot> filteredDocs = [];

                for (var doc in allDocs) {
                  var data = doc.data() as Map<String, dynamic>;
                  String judul = (data['judul'] ?? "").toString().toLowerCase();
                  String lokasi = (data['lokasi'] ?? "").toString().toLowerCase();

                  if (_searchQuery.isEmpty) {
                    filteredDocs.add(doc);
                  } else if (judul.contains(_searchQuery) || lokasi.contains(_searchQuery)) {
                    filteredDocs.add(doc);
                  }
                }

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada laporan penutupan jalan yang cocok.'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF000080),
                          child: Icon(Icons.location_on, color: Colors.white),
                        ),
                        title: Text(
                          data['judul'] ?? 'Tanpa Judul',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Lokasi: ${data['lokasi'] ?? ''}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(data: data),
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