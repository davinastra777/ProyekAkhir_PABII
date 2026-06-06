import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rute_tikus/screens/favorite_screen.dart';
import 'package:rute_tikus/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _imagePicker = ImagePicker();

  String _fullName = 'Memuat nama...';
  String _email = 'Memuat email...';
  String _profilePhotoUrl = '';
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  int _totalLaporan = 0;
  // Tambah state untuk dark mode
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
     _isDark = themeNotifier.value == ThemeMode.dark;
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final postDocs = await _firestore
          .collection('postingan')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _fullName = userDoc.data()?['fullName'] ?? userDoc.data()?['fullname'] ?? 'Pengguna Baru';
          _email = userDoc.data()?['email'] ?? user.email ?? '-';
          _profilePhotoUrl = userDoc.data()?['profilePhotoUrl'] ?? '';
          _totalLaporan = postDocs.docs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullName = 'Gagal memuat data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child(fileName);

      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'profilePhotoUrl': downloadUrl},
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _profilePhotoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e')),
        );
      }
    }
  }

  void _editDataPribadi() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Nama Lengkap'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nama Baru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              final user = _auth.currentUser;
              if (user == null) return;

              await _firestore.collection('users').doc(user.uid).set(
                {'fullName': newName, 'email': user.email},
                SetOptions(merge: true),
              );

              if (mounted) {
                setState(() => _fullName = newName);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama berhasil diperbarui!')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil keluar akun')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarBg = _isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final accent = theme.primaryColor;
    final danger = theme.colorScheme.error;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil Pengguna',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: theme.dividerColor),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _uploadProfilePhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: avatarBg,
                          backgroundImage: _profilePhotoUrl.isNotEmpty
                              ? NetworkImage(_profilePhotoUrl)
                              : null,
                          child: _profilePhotoUrl.isEmpty
                              ? Text(
                                  _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: accent,
                            child: const Icon(Icons.camera_alt, color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person_outline, color: accent),
                          title: Text('Edit Data Pribadi', style: theme.textTheme.bodyLarge),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accent),
                          onTap: _editDataPribadi,
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                        ListTile(
                          leading: Icon(Icons.history, color: accent),
                          title: Text('Riwayat Aktivitas', style: theme.textTheme.bodyLarge),
                          subtitle: Text(
                            'Anda telah membagikan $_totalLaporan laporan blokade.',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Icon(Icons.verified, size: 20, color: accent),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Total kontribusi: $_totalLaporan laporan.')),
                            );
                          },
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                        ListTile(
                          leading: Icon(Icons.favorite_border, color: accent),
                          title: Text('Favorit', style: theme.textTheme.bodyLarge),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accent),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FavoriteScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                        SwitchListTile(
                          secondary: Icon(Icons.dark_mode_outlined, color: accent),
                          title: Text('Mode Gelap', style: theme.textTheme.bodyLarge),
                          value: _isDark,
                          onChanged: (v) {
                            setState(() => _isDark = v);
                            themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                          },
                          activeThumbColor: accent,
                          activeTrackColor: accent.withValues(alpha: 0.5),
                          inactiveTrackColor: _isDark
                              ? const Color(0xFF444444)
                              : const Color(0xFFCCCCCC),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar Akun'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      foregroundColor: theme.colorScheme.onError,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 4,
                      shadowColor: danger.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              ),
            ),
      // Perbaiki bottomNavigationBar — hapus AppColors
      bottomNavigationBar: Container(
        color: _isDark ? Colors.grey[900] : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          'Total kontribusi Anda: $_totalLaporan laporan.',
          style: theme.textTheme.bodySmall?.copyWith(color: accent),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}