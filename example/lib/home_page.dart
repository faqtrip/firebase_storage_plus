import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_plus/firebase_storage_plus.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<Reference, double> _progress = <Reference, double>{};

  @override
  void initState() {
    super.initState();
    OfflineSyncManager.instance.addListener(() {
      setState(() {
        _progress = {
          for (var element in OfflineSyncManager.instance.queuedTasks)
            element.ref: element.progress
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Offline Sync'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: _uploadFile,
                child: const Text('Upload a file'),
              ),
            ),
            for (final Reference ref in _progress.keys)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 50),
                        Expanded(child: Text(ref.name)),
                        const SizedBox(width: 50),
                        TextButton(
                          onPressed: ReferencePlus(ref).delete,
                          child: const Text(
                            'remove',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    FutureBuilder<String>(
                      future: ReferencePlus(ref).getDownloadURL(),
                      builder: (context, snapshot) {
                        return snapshot.hasData
                            ? Text('Uri: ${snapshot.data!}')
                            : const SizedBox();
                      },
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: _progress[ref],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      for (PlatformFile file in result.files) {
        final Reference reference = FirebaseStorage.instance.ref(file.name);
        final Uint8List bytes = File(file.path!).readAsBytesSync();

        ReferencePlus(reference).putData(bytes, keepInStorage: true);
      }
    }
  }
}
