import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'comment_section.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String blockadeId;

  const DetailScreen({super.key, required this.data, required this.blockadeId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

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
        'jenis': widget.data['jenis'],
        'jam': widget.data['jam'],
        'estimasiHari': widget.data['estimasiHari'],
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

    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
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
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final borderColor = theme.dividerColor;
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Penutupan',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: theme.colorScheme.error,
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
                    color: theme.dividerColor,
                    child: Center(
                      child: Icon(Icons.image_outlined, size: 60, color: theme.primaryColor),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['judul'] ?? 'Tanpa Judul', style: titleStyle),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.data['jenis'] != null)
                        _Chip(
                          icon: Icons.label,                        
                          label: widget.data['jenis'],                      
                          color: accent,
                        ),
                      if (widget.data['jam'] != null)
                        _Chip(
                          icon: Icons.access_time,
                          label: widget.data['jam'],
                          color: accent,
                        ),
                      if (widget.data['estimasiHari'] != null)
                        _Chip(
                          icon: Icons.calendar_today,
                          label: '${widget.data['estimasiHari']} hari',
                          color: accent,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.description,
                    label: 'Deskripsi',
                    value: widget.data['deskripsi'] ?? '-',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  if (widget.data['lokasi'] != null)
                    _InfoRow(
                      icon: Icons.signpost,
                      label: 'Lokasi',
                      value: widget.data['lokasi'],
                      theme: theme,
                    ),
                  if (widget.data['jam'] != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Jam Operasional',
                      value: widget.data['jam'],
                      theme: theme,
                    ),
                  ],
                  if (widget.data['estimasiHari'] != null) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Durasi',
                      value: '${widget.data['estimasiHari']} hari',
                      theme: theme,
                    ),
                  ],
                  if (widget.data['tempat_tujuan'] != null && widget.data['tempat_tujuan'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.place,
                      label: 'Tujuan Terdekat',
                      value: widget.data['tempat_tujuan'],
                      theme: theme,
                    ),
                  ],
                  if (widget.data['rute_alternatif'] != null && widget.data['rute_alternatif'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.alt_route,
                      label: 'Rute Alternatif',
                      value: widget.data['rute_alternatif'],
                      theme: theme,
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Buka di Google Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CommentsSection(blockadeId: widget.blockadeId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, required this.theme});

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}