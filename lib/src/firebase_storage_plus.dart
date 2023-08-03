part of firebase_storage_plus;

class OfflineSyncManager extends ChangeNotifier {
  OfflineSyncManager._();

  static final OfflineSyncManager _instance = OfflineSyncManager._();

  static OfflineSyncManager get instance {
    return OfflineSyncManager._instance;
  }

  /// Firestore fullPath to UploadTask
  final Map<String, QueuedTaskInfo> _tasks = {};

  late final String _storageDirectory;

  ///List of queued tasks
  List<QueuedTaskInfo> get queuedTasks => List.unmodifiable(_tasks.values);

  // ignore: use_setters_to_change_properties
  void initializeStorage({required Directory storageDirectory}) =>
      _storageDirectory = storageDirectory.path;

  void resumeUnfinishedUpload() => _resumeUnfinishedUpload();

  /// Adds a document to a queue
  UploadTask _addToQueue({
    Uint8List? bytes,
    File? file, //should be present if isResumed
    String? stringData,
    required _LocalFileMetadata metadata,
    bool isResumed = false,
  }) {
    final Reference fileRef = FirebaseStorage.instance.ref(metadata.fullPath);
    final ReferencePlus fileRefPlus = ReferencePlus(fileRef);

    late UploadTask task;
    late final int bytesLength;

    switch (metadata.functionName) {
      case 'putData':
        late final Uint8List _bytes;

        if (!isResumed) {
          _bytes = bytes!;
          _saveBytes(bytes: bytes, metadata: metadata);
        } else {
          _bytes = file!.readAsBytesSync();
        }

        bytesLength = _bytes.length;
        task = fileRefPlus.putData(
          _bytes,
          keepInStorage: false,
          metadata: metadata.settableMetadata,
        );
        break;
      case 'putFile':
        final Uint8List _bytes = file!.readAsBytesSync();

        if (!isResumed) {
          _saveBytes(bytes: _bytes, metadata: metadata);
        }

        bytesLength = _bytes.length;
        task = fileRefPlus.putFile(
          file,
          keepInStorage: false,
          metadata: metadata.settableMetadata,
        );
        break;
      case 'putString':
        late final Uint8List _bytes;
        late final String _stringData;

        if (!isResumed) {
          _stringData = stringData!;
          final Uint8List _bytes = Uint8List.fromList(utf8.encode(stringData));
          _saveBytes(bytes: _bytes, metadata: metadata);
        } else {
          _bytes = file!.readAsBytesSync();
          _stringData = utf8.decode(file.readAsBytesSync());
        }

        bytesLength = _bytes.length;
        task = fileRefPlus.putString(
          _stringData,
          format: metadata.putStringFormat ?? PutStringFormat.raw,
          keepInStorage: false,
          metadata: metadata.settableMetadata,
        );
        break;
    }

    _tasks[metadata.fullPath] = QueuedTaskInfo(
      ref: fileRef,
      task: task,
      localPath: '$_storageDirectory/${metadata.localFileName}',
    );
    notifyListeners();

    task.snapshotEvents.listen((event) {
      if (event.state == TaskState.canceled || event.state == TaskState.error) {
        _removeFromQueue(fileRef);

        return;
      }

      _tasks[metadata.fullPath]?._progress =
          event.bytesTransferred / bytesLength;
      notifyListeners();
    });
    task.whenComplete(() {
      _removeFromQueue(fileRef);
      notifyListeners();
    });

    return task;
  }

  void _removeFromQueue(Reference ref) {
    if (_tasks[ref.fullPath]?.task.snapshot.state == TaskState.running) {
      _tasks[ref.fullPath]?.task.cancel();
    }
    _removeLocalFile(ref.fullPath);
    _tasks.remove(ref.fullPath);
  }

  void _removeLocalFile(String firestoreFullePath) {
    try {
      final String localPath = _tasks[firestoreFullePath]!.localPath;
      File(localPath).deleteSync();
      File('$localPath.metadata').deleteSync();
    } catch (e) {
      return;
    }
  }

  /// Checks if a file is still in in queue
  bool _isInQueue(String firestoreFullePath) {
    return _tasks.keys.contains(firestoreFullePath);
  }

  /// Get a local file
  Future<Uint8List?> _getLocalFile(String firestoreFullePath) async {
    try {
      final String localPath = _tasks[firestoreFullePath]!.localPath;
      return File(localPath).readAsBytesSync();
    } catch (e) {
      return null;
    }
  }

  void _resumeUnfinishedUpload() {
    final Directory directory = Directory(_storageDirectory);
    final List<FileSystemEntity> fileEntities = directory.listSync();

    for (final FileSystemEntity entity in fileEntities) {
      final String path = entity.path;
      if (path.endsWith('.metadata')) {
        final String fileToUploadPath = path.replaceAll('.metadata', '');
        if (File(fileToUploadPath).existsSync()) {
          String metadataContent = File(entity.path).readAsStringSync();

          _LocalFileMetadata metadata = _LocalFileMetadata.fromJson(
            jsonDecode(metadataContent),
          );

          _addToQueue(
            file: File(fileToUploadPath),
            metadata: metadata,
            isResumed: true,
          );
        } else {
          File(path).deleteSync();
        }
      }
    }
  }

  Future<void> _saveBytes({
    required Uint8List bytes,
    required _LocalFileMetadata metadata,
  }) async {
    final File file = File('$_storageDirectory/${metadata.localFileName}');
    await file.writeAsBytes(bytes);
    final File metadataFile = File('${file.path}.metadata');
    await metadataFile.writeAsString(jsonEncode(metadata.toJson()));
  }
}
