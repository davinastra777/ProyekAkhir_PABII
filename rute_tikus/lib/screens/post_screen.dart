import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _image;
  String? _base64Image;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _jamController = TextEditingController();
  final _tujuanController = TextEditingController();
  final _ruteAlternatifController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _image = File(pickedFile.path);
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _submitPost() async {
    if (_base64Image == null || _judulController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto dan Judul wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _getLocation();
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonim';

      await FirebaseFirestore.instance.collection("postingan").add({
        'fotoBase64': _base64Image,
        'judul': _judulController.text,
        'deskripsi': _deskripsiController.text,
        'lokasi': _lokasiController.text,
        'jam': _jamController.text,
        'tempat_tujuan': _tujuanController.text,
        'rute_alternatif': _ruteAlternatifController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'userId': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Laporan berhasil diunggah!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Baru'), backgroundColor: const Color.fromARGB(255, 1, 1, 129)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: _judulController, decoration: const InputDecoration(labelText: 'Judul (Contoh: Hajatan Nikah)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _deskripsiController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _lokasiController, decoration: const InputDecoration(labelText: 'Lokasi (Nama Jalan)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _jamController, decoration: const InputDecoration(labelText: 'Waktu (cth: 08:00 - 15:00)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _tujuanController, decoration: const InputDecoration(labelText: 'Tempat Tujuan Terdekat', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _ruteAlternatifController, decoration: const InputDecoration(labelText: 'Saran Rute Alternatif', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 1, 1, 129), minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Upload Laporan'),
                  ),
          ],
        ),
      ),
    );
  }
}