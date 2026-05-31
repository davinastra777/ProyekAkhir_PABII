import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String _fullName = "Memuat nama...";
  String _email = "Memuat email...";
  bool _isDarkMode = false;
  bool _isLoading = true;
  int _totalLaporan = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      
      final postDocs = await _firestore
          .collection('postingan')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (mounted) {
        setState(() {
          _fullName = userDoc.data()?['fullName'] ??
              userDoc.data()?['fullname'] ??
              'Pengguna Baru';
          _email = userDoc.data()?['email'] ?? user.email ?? '-';
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

  void _editDataPribadi() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Nama Lengkap'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
              labelText: 'Nama Baru', border: OutlineInputBorder()),
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

              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .set({'fullName': newName, 'email': user.email},
                      SetOptions(merge: true));

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
    final bg = _isDarkMode ? Colors.grey[900]! : Colors.grey[100]!;
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    final cardColor = _isDarkMode ? Colors.grey[800]! : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: const Color(0xFF000080),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF000080),
                    child: Text(
                      _fullName.isNotEmpty
                          ? _fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 40,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_fullName,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  Text(_email,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 25),

                  Card(
                    color: cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline,
                              color: Color(0xFF000080)),
                          title: Text('Edit Data Pribadi',
                              style: TextStyle(color: textColor)),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16),
                          onTap: _editDataPribadi,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.history,
                              color: Color(0xFF000080)),
                          title: Text('Riwayat Aktivitas',
                              style: TextStyle(color: textColor)),
                          subtitle: Text(
                            'Anda telah membagikan $_totalLaporan laporan blokade.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.verified,
                              size: 20, color: Colors.green),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Total kontribusi: $_totalLaporan laporan.'),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined,
                              color: Color(0xFF000080)),
                          title: Text('Mode Gelap',
                              style: TextStyle(color: textColor)),
                          value: _isDarkMode,
                          onChanged: (v) => setState(() => _isDarkMode = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Keluar Akun',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Total kontribusi Anda: $_totalLaporan laporan.',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}