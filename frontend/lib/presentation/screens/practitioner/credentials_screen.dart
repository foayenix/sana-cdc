import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sana_app/core/widgets/custom_button.dart';
import 'package:sana_app/core/widgets/loading_indicator.dart';
import 'package:sana_app/data/services/practitioners_service.dart';
import 'package:sana_app/data/services/upload_service.dart';

class CredentialsScreen extends ConsumerStatefulWidget {
  const CredentialsScreen({super.key});

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  final List<Map<String, dynamic>> _uploadedFiles = [];
  final List<Map<String, String>> _pendingFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  Future<void> _loadExistingCredentials() async {
    try {
      final practitionersService = ref.read(practitionersServiceProvider);
      final profile = await practitionersService.getProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading credentials: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFiles() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Picker'),
          content: const Text(
            'Add file_picker package to enable file selection.\n\n'
            'Supported: PDF, JPG, PNG\nMax size: 10MB',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _simulateFileSelection();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _simulateFileSelection() {
    setState(() {
      _pendingFiles.addAll([
        {'name': 'Certificate.pdf', 'path': '/file1.pdf', 'size': '2.3 MB'},
        {'name': 'Insurance.pdf', 'path': '/file2.pdf', 'size': '1.8 MB'},
      ]);
    });
  }

  void _removeFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  Future<void> _uploadCredentials() async {
    if (_pendingFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final practitionersService = ref.read(practitionersServiceProvider);
      final fileKeys = <String>[];

      for (var i = 0; i < _pendingFiles.length; i++) {
        final file = _pendingFiles[i];
        setState(() {
          _uploadProgress = (i + 1) / _pendingFiles.length;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        fileKeys.add('credentials/${file['name']}');
      }

      await practitionersService.uploadCredentials(fileKeys);

      if (mounted) {
        setState(() {
          _uploadedFiles.addAll(_pendingFiles.map((file) => {
                ...file,
                'uploadedAt': DateTime.now().toIso8601String(),
              }));
          _pendingFiles.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credentials uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credentials')),
      body: _isUploading
          ? _buildUploadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Required: qualifications, membership, insurance',
                              style: TextStyle(color: Colors.blue[900])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_pendingFiles.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file, size: 64, color: Colors.grey[400]),
                            const Text('No files selected'),
                          ],
                        ),
                      ),
                    ),
                  if (_pendingFiles.isNotEmpty)
                    ..._pendingFiles.asMap().entries.map((entry) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(entry.value['name']!),
                          subtitle: Text(entry.value['size']!),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _removeFile(entry.key),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Files'),
                  ),
                  if (_pendingFiles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Upload Credentials',
                      onPressed: _uploadCredentials,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildUploadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Uploading...', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _uploadProgress, minHeight: 8),
        ],
      ),
    );
  }
}
