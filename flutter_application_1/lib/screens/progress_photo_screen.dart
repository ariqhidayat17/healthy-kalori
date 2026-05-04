import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class ProgressPhotoScreen extends StatefulWidget {
  const ProgressPhotoScreen({super.key});

  @override
  State<ProgressPhotoScreen> createState() => _ProgressPhotoScreenState();
}

class _ProgressPhotoScreenState extends State<ProgressPhotoScreen> {
  List<Map<String, dynamic>> _photos = [];
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  bool _isUnlocked = false;
  bool _isPinSet = false;
  String _savedPin = '';
  String _inputPin = '';

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
    _loadPhotos();
  }

  Future<void> _checkPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('progress_pin');
    if (pin != null && pin.isNotEmpty) {
      setState(() {
        _isPinSet = true;
        _savedPin = pin;
        _isUnlocked = false;
      });
    } else {
      setState(() {
        _isPinSet = false;
        _isUnlocked = true;
      });
    }
  }

  Future<void> _loadPhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosStr = prefs.getString('progress_photos');
    if (photosStr != null) {
      final List<dynamic> decoded = jsonDecode(photosStr);
      setState(() {
        _photos = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        // Urutkan dari yang terbaru
        _photos.sort((a, b) => b['dateTs'].compareTo(a['dateTs']));
      });
    }
  }

  Future<void> _savePhotos() async {
    final prefs = await SharedPreferences.getInstance();
    final photosStr = jsonEncode(_photos);
    await prefs.setString('progress_photos', photosStr);
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image != null) {
      _saveImageLocally(image);
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      _saveImageLocally(image);
    }
  }

  Future<void> _saveImageLocally(XFile image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String id = _uuid.v4();
      final String fileName = 'progress_$id.jpg';
      final String savedPath = '${directory.path}/$fileName';

      // Pindahkan file ke temporary -> persistent document directory
      await File(image.path).copy(savedPath);

      final now = DateTime.now();
      final dateStr = DateFormat('MMM yyyy').format(now);
      
      setState(() {
        _photos.add({
          'id': id,
          'path': savedPath,
          'dateStr': dateStr,
          'dateTs': now.millisecondsSinceEpoch,
          'weight': 0.0, // Bisa diupdate nanti via dialog
        });
        _photos.sort((a, b) => b['dateTs'].compareTo(a['dateTs']));
      });

      await _savePhotos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto: $e')),
      );
    }
  }

  Future<void> _deletePhoto(String id) async {
    setState(() {
      _photos.removeWhere((photo) => photo['id'] == id);
    });
    await _savePhotos();
  }

  void _verifyPin() {
    if (_inputPin == _savedPin) {
      setState(() {
        _isUnlocked = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Salah!')));
      setState(() {
        _inputPin = '';
      });
    }
  }

  void _showSetPinDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String newPin = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(_isPinSet ? 'Ubah PIN' : 'Setel PIN (4 Angka)', style: const TextStyle(color: Colors.white)),
              content: TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => newPin = val,
                decoration: const InputDecoration(hintText: 'xxxx', hintStyle: TextStyle(color: Colors.grey)),
              ),
              actions: [
                if (_isPinSet)
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('progress_pin');
                      setState(() {
                        _isPinSet = false;
                        _savedPin = '';
                      });
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kunci PIN Dihapus')));
                    },
                    child: const Text('Hapus PIN', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPin.length == 4) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('progress_pin', newPin);
                      setState(() {
                        _isPinSet = true;
                        _savedPin = newPin;
                      });
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN Berhasil Disimpan')));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                  child: const Text('Simpan', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildPinScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Color(0xFFD4AF37)),
          const SizedBox(height: 20),
          const Text('Masukkan PIN Galeri', style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _inputPin.length ? const Color(0xFFD4AF37) : Colors.grey.shade800,
                ),
              );
            }),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 280,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 1; i <= 9; i++) _buildNumButton(i.toString()),
                const SizedBox.shrink(),
                _buildNumButton('0'),
                _buildNumButton('<', isDelete: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNumButton(String text, {bool isDelete = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isDelete) {
            if (_inputPin.isNotEmpty) {
              _inputPin = _inputPin.substring(0, _inputPin.length - 1);
            }
          } else {
            if (_inputPin.length < 4) {
              _inputPin += text;
            }
            if (_inputPin.length == 4) {
              _verifyPin();
            }
          }
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade900,
        ),
        child: isDelete 
            ? const Icon(Icons.backspace, color: Colors.white)
            : Text(text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked && _isPinSet) {
      return Scaffold(
        appBar: AppBar(title: const Text('Keamanan Galeri'), centerTitle: true),
        body: _buildPinScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Progres Fisik'),
        actions: [
          IconButton(
            icon: Icon(_isPinSet ? Icons.lock : Icons.lock_open, color: const Color(0xFFD4AF37)),
            onPressed: _showSetPinDialog,
            tooltip: 'Keamanan PIN',
          )
        ],
      ),
      body: _photos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_size_select_actual_outlined, size: 80, color: Colors.grey.shade600),
                  const SizedBox(height: 16),
                  const Text('Belum ada foto progress', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Mulai dokumentasikan transformasi badanmu!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.75,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(photo['path']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image)),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black87, Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo['dateStr'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Foto?'),
                                content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deletePhoto(photo['id']);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCF6679)),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera_btn',
            onPressed: _takePhoto,
            backgroundColor: const Color(0xFFD4AF37),
            child: const Icon(Icons.camera_alt, color: Colors.black),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'gallery_btn',
            onPressed: _pickPhoto,
            backgroundColor: Colors.grey.shade800,
            child: const Icon(Icons.photo_library, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
