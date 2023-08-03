import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_plus/firebase_storage_plus.dart';
import 'package:firestore_offline_sync/home_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Future.sync(
    () async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (!kIsWeb) {
        OfflineSyncManager.instance.initializeStorage(
          storageDirectory: await getApplicationDocumentsDirectory(),
        );
        OfflineSyncManager.instance.resumeUnfinishedUpload();
      }
    },
  ).then(
    (_) => runApp(const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Offline Sync',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
