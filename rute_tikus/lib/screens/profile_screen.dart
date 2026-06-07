import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rute_tikus/screens/favorite_screen.dart';
import 'package:rute_tikus/screens/sign_in_screen.dart';
import 'package:rute_tikus/main.dart';
import 'package:rute_tikus/screens/riwayat_screen.dart';

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
  String _noHp = '-';
  String _fotoProfilBase64 = '';
  
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  int _totalLaporan = 0;
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
          _noHp = userDoc.data()?['noHp'] ?? '-';
          _fotoProfilBase64 = userDoc.data()?['fotoProfil'] ?? '';
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
        imageQuality: 40,
        maxWidth: 600,
      );
      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      await _firestore.collection('users').doc(user.uid).set(
        {'fotoProfil': base64String},
        SetOptions(merge: true),
      );

      if (mounted) {
        setState(() {
          _fotoProfilBase64 = base64String;
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
    final phoneController = TextEditingController(text: _noHp == '-' ? '' : _noHp);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Data Pribadi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
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
              final newPhone = phoneController.text.trim();

              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama tidak boleh kosong!')),
                );
                return;
              }
              
              final user = _auth.currentUser;
              if (user == null) return;

              await _firestore.collection('users').doc(user.uid).set(
                {
                  'fullName': newName,
                  'noHp': newPhone,
                },
                SetOptions(merge: true),
              );

              if (mounted) {
                setState(() {
                  _fullName = newName;
                  _noHp = newPhone.isNotEmpty ? newPhone : '-';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil diperbarui!')),
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
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
                          backgroundImage: _fotoProfilBase64.isNotEmpty
                              ? MemoryImage(base64Decode(_fotoProfilBase64))
                              : null,
                          child: _fotoProfilBase64.isEmpty
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
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: accent,
                            child: Icon(Icons.camera_alt, color: _isDark ? Colors.black : Colors.white, size: 18),
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
                  const SizedBox(height: 4),
                  Text(
                    _noHp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
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
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: accent),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RiwayatScreen()),
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
      bottomNavigationBar: Container(
        color: _isDark ? Colors.grey[900] : theme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          'Total kontribusi Anda: $_totalLaporan laporan.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: _isDark ? accent : Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}