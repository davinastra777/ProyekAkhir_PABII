import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const DetailScreen({super.key, required this.data});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final lat = widget.data['latitude'] ?? -6.200000;
    final lng = widget.data['longitude'] ?? 106.816666;
    final LatLng location = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penutupan'),
        backgroundColor: const Color.fromARGB(255, 1, 1, 129),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: () async {
              setState(() {
                _isFavorite = !_isFavorite;
              });

              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              if (_isFavorite) {
                await FirebaseFirestore.instance.collection('favorites').add({
                  'userId': uid,
                  'judul': widget.data['judul'],
                  'deskripsi': widget.data['deskripsi'],
                  'lokasi': widget.data['lokasi'],
                  'jam': widget.data['jam'],
                  'tempat_tujuan': widget.data['tempat_tujuan'],
                  'rute_alternatif': widget.data['rute_alternatif'],
                  'fotoBase64': widget.data['fotoBase64'],
                  'latitude': widget.data['latitude'],
                  'longitude': widget.data['longitude'],
                  'timestamp': FieldValue.serverTimestamp(),
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke Favorit!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batal menyukai (Hapus lewat menu favorit)')));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.data['fotoBase64'] != null
                ? Image.memory(base64Decode(widget.data['fotoBase64']), height: 250, width: double.infinity, fit: BoxFit.cover)
                : Container(height: 250, color: Colors.grey, child: const Icon(Icons.image, size: 50)),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['judul'] ?? 'Tanpa Judul',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold
                    )
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      Text(' Waktu: ${widget.data['jam'] ?? ''}')
                      ]
                    ),

                  const SizedBox(height: 8),

                  Text('Deskripsi: ${widget.data['deskripsi'] ?? '-'}'),
                  
                  const Divider(),

                  Text('Tujuan: ${widget.data['tempat_tujuan'] ?? '-'}'),

                  Text('Rute Alternatif: ${widget.data['rute_alternatif'] ?? '-'}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold
                    )
                  ),

                  const SizedBox(height: 16),
                  
                  // Peta Lokasi
                  const Text('Lokasi di Peta:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                  
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: location, zoom: 16.0),
                      markers: {
                        Marker(markerId: const MarkerId('lokasi'), position: location)
                      },
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}