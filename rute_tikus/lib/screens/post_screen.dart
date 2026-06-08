import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum BlockadeType {
  tendaHajatan('Tenda Hajatan', Icons.celebration, Color(0xFFFF9800)),
  penutupanJalan('Penutupan Jalan', Icons.block, Color(0xFFF44336)),
  pekerjaanJalan('Pekerjaan Jalan', Icons.construction, Color(0xFFFFC107)),
  pasarDadakan('Pasar Dadakan', Icons.storefront, Color(0xFF4CAF50)),
  lainnya('Lainnya', Icons.help_outline, Color(0xFF2196F3));

  const BlockadeType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

class AddBlockadePostScreen extends StatefulWidget {
  const AddBlockadePostScreen({super.key});

  @override
  State<AddBlockadePostScreen> createState() => _AddBlockadePostScreenState();
}

class _AddBlockadePostScreenState extends State<AddBlockadePostScreen>
    with SingleTickerProviderStateMixin {
  Uint8List? _imageBytes;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationNameController = TextEditingController();
  final _altRouteController = TextEditingController();
  final _nearestDestController = TextEditingController();

  BlockadeType _selectedType = BlockadeType.tendaHajatan;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  bool _isUploading = false;

  late AnimationController _btnAnim;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _btnScale = CurvedAnimation(parent: _btnAnim, curve: Curves.elasticOut);
    _btnAnim.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    _altRouteController.dispose();
    _nearestDestController.dispose();
    _btnAnim.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Layanan lokasi tidak aktif. Aktifkan GPS terlebih dahulu.');
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          _showSnack('Izin lokasi ditolak.');
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });

      _showSnack('Lokasi berhasil didapatkan');
    } catch (e) {
      debugPrint('Lokasi gagal: $e');
      _showSnack('Gagal mendapatkan lokasi: $e');
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _base64Image = base64Encode(bytes);
      });
    } catch (e) {
      _showSnack('Gagal memilih gambar: $e');
    }
  }

  void _showImageSourceSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Ambil Foto'),
              subtitle: const Text('Foto langsung kondisi blokade'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor,
                child: const Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: _startDate,
    firstDate: DateTime.now().subtract(const Duration(days: 1)),
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  if (picked != null) {
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate.add(const Duration(days: 1));
      }
    });
  }
}

  Future<void> _pickEndDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: _endDate.isAfter(_startDate)
        ? _endDate
        : _startDate.add(const Duration(days: 1)),
    firstDate: _startDate,
    lastDate: DateTime.now().add(const Duration(days: 365)),
  );

  if (picked != null) {
    setState(() {
      _endDate = picked;
    });
  }
}

  Future<void> _pickOpenTime() async {
    final t = await showTimePicker(
      context: context, 
      initialTime: _openTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t != null) setState(() => _openTime = t);
  }

  Future<void> _pickCloseTime() async {
    final t = await showTimePicker(
      context: context, 
      initialTime: _closeTime,
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t != null) setState(() => _closeTime = t);
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int get _durationDays => _endDate.difference(_startDate).inDays + 1;

  Future<void> _submit() async {
    if (_base64Image == null) {
      _showSnack('Harap tambahkan foto blokade');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Judul wajib diisi');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showSnack('Harap ambil lokasi terlebih dahulu');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        _showSnack('Silakan masuk terlebih dahulu');
        setState(() => _isUploading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final fullName = userDoc.data()?['fullName'] ?? userDoc.data()?['fullname'] ?? 'Anonim';

      await FirebaseFirestore.instance.collection('postingan').add({
        'fotoBase64': _base64Image,
        'judul': _titleController.text.trim(),
        'deskripsi': _descController.text.trim(),
        'jenis': _selectedType.label,
        'lokasi': _locationNameController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'tanggalMulai': _startDate.toIso8601String(),
        'tanggalSelesai': _endDate.toIso8601String(),
        'estimasiHari': _durationDays,
        'jam': '${_fmtTime(_openTime)} s/d ${_fmtTime(_closeTime)}',
        'tempat_tujuan': _nearestDestController.text.trim(),
        'rute_alternatif': _altRouteController.text.trim(),
        'fullName': fullName,
        'userId': uid,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showSnack('Gagal mengunggah: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.primaryColor;
    final borderColor = theme.dividerColor;
    final surface = theme.cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buat Laporan Blokade',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(label: 'Foto Blokade', color: accent),
            const SizedBox(height: 8),
            _buildImagePicker(theme, accent, borderColor, surface),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Jenis Blokade', color: accent),
            const SizedBox(height: 8),
            _buildTypeSelector(theme, accent, borderColor, surface),
            const SizedBox(height: 16),
            _buildField(
              controller: _titleController,
              label: 'Judul Laporan',
              hint: 'Contoh: Tenda Hajatan Nikah RT 04',
              icon: Icons.title,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _descController,
              label: 'Deskripsi Kondisi',
              hint: 'Jelaskan kondisi blokade...',
              icon: Icons.description,
              theme: theme,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Lokasi Blokade', color: accent),
            const SizedBox(height: 8),
            _buildField(
              controller: _locationNameController,
              label: 'Nama Jalan / Lorong',
              hint: 'Contoh: Jl.Rajawali, Gang Melati',
              icon: Icons.signpost,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildLocationButton(theme, accent, borderColor),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Estimasi Durasi', color: accent),
            const SizedBox(height: 8),
            _buildDurationSection(theme, accent, borderColor, surface),
            const SizedBox(height: 20),
            _SectionHeader(label: 'Rute Alternatif', color: accent),
            const SizedBox(height: 8),
            _buildField(
              controller: _nearestDestController,
              label: 'Tempat Tujuan Terdekat',
              hint: 'Contoh: Masjid Al-Hidayah, Minimarket XYZ',
              icon: Icons.place,
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _altRouteController,
              label: 'Saran Rute Alternatif',
              hint: 'Contoh: Belok kiri di pertigaan, lewat Gang Dahlia',
              icon: Icons.alt_route,
              theme: theme,
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ScaleTransition(
              scale: _btnScale,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _submit,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: Text(
                    _isUploading ? 'Mengunggah...' : 'Upload Laporan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: accent.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme, Color accent, Color borderColor, Color surface) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _imageBytes != null ? 220 : 160,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _imageBytes != null ? accent : borderColor,
            width: _imageBytes != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _imageBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_rounded, size: 44, color: accent),
                  const SizedBox(height: 8),
                  Text(
                    'Tap untuk tambah foto blokade',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kamera atau galeri',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, Color accent, Color borderColor, Color surface) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: BlockadeType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final type = BlockadeType.values[i];
          final selected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? accent : surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? accent : borderColor),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: accent.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(type.icon, color: selected ? Colors.white : type.color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    type.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : theme.textTheme.bodySmall?.color,
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationButton(ThemeData theme, Color accent, Color borderColor) {
    final bool hasLocation = _latitude != null && _longitude != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasLocation ? accent : borderColor,
          width: hasLocation ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: hasLocation
                ? Icon(Icons.check_circle, key: const ValueKey('check'), color: accent, size: 28)
                : Icon(Icons.location_off, key: const ValueKey('off'), color: theme.dividerColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation ? 'Lokasi berhasil diambil' : 'Belum ada lokasi',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasLocation ? accent : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                      : 'Tap tombol untuk ambil koordinat GPS',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasLocation ? theme.textTheme.bodySmall?.color : theme.dividerColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isGettingLocation ? null : _getLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(hasLocation ? Icons.refresh : Icons.my_location, size: 16),
            label: Text(
              hasLocation ? 'Perbarui' : 'Ambil',
              style: const TextStyle(fontSize: 13),
            ),
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
    );
  }

  Widget _buildDurationSection(ThemeData theme, Color accent, Color borderColor, Color surface) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Mulai',
                  value: _fmtDate(_startDate),
                  icon: Icons.calendar_today,
                  color: accent,
                  onTap: _pickStartDate,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
              ),
              Expanded(
                child: _DateTile(
                  label: 'Selesai',
                  value: _fmtDate(_endDate),
                  icon: Icons.event_available,
                  color: accent,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Durasi: $_durationDays hari',
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Jam Blokade:', style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color)),
              const Spacer(),
              _TimePill(
                time: _fmtTime(_openTime),
                label: 'Buka',
                color: accent,
                onTap: _pickOpenTime,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('s/d', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              _TimePill(
                time: _fmtTime(_closeTime),
                label: 'Tutup',
                color: theme.colorScheme.error,
                onTap: _pickCloseTime,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        labelStyle: theme.textTheme.bodySmall,
        hintStyle: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: color.withOpacity(0.2))),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.time, required this.label, required this.color, required this.onTap});

  final String time;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color)),
            const SizedBox(height: 2),
            Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}