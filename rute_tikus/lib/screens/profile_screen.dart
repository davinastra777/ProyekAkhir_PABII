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

  void _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        QuerySnapshot postDocs = await _firestore.collection('postingan').where('userId', isEqualTo: user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _fullName = userDoc['fullName'] ?? "Tanpa Nama";
            _email = userDoc['email'] ?? user.email ?? "-";
            _totalLaporan = postDocs.docs.length;
            _isLoading = false;
          });
        } else {
          setState(() {
            _fullName = "Pengguna Baru";
            _email = user.email ?? "-";
            _totalLaporan = postDocs.docs.length;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _fullName = "Gagal memuat data";
          _isLoading = false;
        });
      }
    }
  }

  void _editDataPribadi() {
    final nameController = TextEditingController(text: _fullName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama Lengkap'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Baru', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final user = _auth.currentUser;
                if (user != null) {
                  await _firestore.collection('users').doc(user.uid).set({
                    'fullName': newName,
                    'email': user.email,
                  }, SetOptions(merge: true));
                  
                  setState(() {
                    _fullName = newName;
                    _email = user.email ?? "-"; 
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama berhasil diperbarui!')),
                    );
                  }
                }
              }
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil keluar akun')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color cardColor;

    if (_isDarkMode) {
      backgroundColor = Colors.grey[900]!;
      textColor = Colors.white;
      cardColor = Colors.grey[800]!;
    } else {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.black;
      cardColor = Colors.white;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        backgroundColor: const Color(0xFF000080),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF000080),
                    child: Text(
                      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _fullName,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),

                  Card(
                    color: cardColor,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline, color: Color(0xFF000080)),
                          title: Text('Edit Data Pribadi', style: TextStyle(color: textColor)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _editDataPribadi,
                        ),
                        const Divider(height: 1),

                        ListTile(
                          leading: const Icon(Icons.history, color: const Color.fromARGB(255, 1, 1, 129)),
                          title: Text('Riwayat Aktivitas', style: TextStyle(color: textColor)),
                          subtitle: Text('Anda telah membagikan $_totalLaporan laporan jalan.', style: const TextStyle(color: Colors.grey)),
                          trailing: const Icon(Icons.verified, size: 20, color: Colors.green),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Total kontribusi Anda: $_totalLaporan laporan.')),
                            );
                          },
                        ),
                        const Divider(height: 1),

                        SwitchListTile(
                          secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF000080)),
                          title: Text('Mode Gelap', style: TextStyle(color: textColor)),
                          value: _isDarkMode,
                          onChanged: (bool value) {
                            setState(() {
                              _isDarkMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Keluar Akun', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}