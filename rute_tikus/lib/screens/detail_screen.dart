import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comment_section.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String blockadeId;

  const DetailScreen({
    super.key,
    required this.data,
    required this.blockadeId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  static const primary = Color(0xFF1A237E);
  static const accent = Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final existing = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: uid)
        .where('postinganId', isEqualTo: widget.blockadeId)
        .get();

    if (mounted) {
      setState(() => _isFavorite = existing.docs.isNotEmpty);
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final existing = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: uid)
        .where('postinganId', isEqualTo: widget.blockadeId)
        .get();

    if (existing.docs.isNotEmpty) {
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }
      setState(() => _isFavorite = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dihapus dari favorit')),
        );
      }
    } else {
      await FirebaseFirestore.instance.collection('favorites').add({
        'userId': uid,
        'postinganId': widget.blockadeId,
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
      setState(() => _isFavorite = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ditambahkan ke Favorit!')),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    final lat = widget.data['latitude'];
    final lng = widget.data['longitude'];
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat tidak tersedia')),
      );
      return;
    }

    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.data['latitude'];
    final lng = widget.data['longitude'];
    final hasLocation = lat != null && lng != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Detail Penutupan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red[300],
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.data['fotoBase64'] != null
                ? Image.memory(
                    base64Decode(widget.data['fotoBase64']),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data['judul'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.data['type'] != null)
                        _Chip(
                          icon: Icons.label,
                          label: widget.data['type'],
                          color: accent,
                        ),
                      if (widget.data['jam'] != null)
                        _Chip(
                          icon: Icons.access_time,
                          label: widget.data['jam'],
                          color: primary,
                        ),
                      if (widget.data['durationDays'] != null)
                        _Chip(
                          icon: Icons.calendar_today,
                          label: '${widget.data['durationDays']} hari',
                          color: Colors.teal,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  _InfoRow(
                    icon: Icons.description,
                    label: 'Deskripsi',
                    value: widget.data['deskripsi'] ?? '-',
                    color: primary,
                  ),

                  const SizedBox(height: 10),

                  if (widget.data['lokasi'] != null)
                    _InfoRow(
                      icon: Icons.signpost,
                      label: 'Lokasi',
                      value: widget.data['lokasi'],
                      color: primary,
                    ),

                  const SizedBox(height: 10),

                  _InfoRow(
                    icon: Icons.place,
                    label: 'Tempat Tujuan',
                    value: widget.data['tempat_tujuan'] ?? '-',
                    color: primary,
                  ),

                  const SizedBox(height: 10),

                  _InfoRow(
                    icon: Icons.alt_route,
                    label: 'Rute Alternatif',
                    value: widget.data['rute_alternatif'] ?? '-',
                    color: Colors.green[700]!,
                    valueColor: Colors.green[700],
                    valueBold: true,
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),


                  const Text(
                    '📍 Lokasi di Peta',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasLocation ? primary : Colors.grey[300]!,
                        width: hasLocation ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          hasLocation ? Icons.location_on : Icons.location_off,
                          color: hasLocation ? primary : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasLocation
                                    ? 'Koordinat tersedia'
                                    : 'Koordinat tidak tersedia',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: hasLocation
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                              if (hasLocation)
                                Text(
                                  '${(lat as double).toStringAsFixed(5)}, '
                                  '${(lng as double).toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (hasLocation)
                          ElevatedButton.icon(
                            onPressed: _openInMaps,
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Buka Maps'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
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

                  const SizedBox(height: 16),
                ],
              ),
            ),

            const Divider(thickness: 1),
            CommentsSection(blockadeId: widget.blockadeId),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.valueColor,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                    fontWeight:
                        valueBold ? FontWeight.w700 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}