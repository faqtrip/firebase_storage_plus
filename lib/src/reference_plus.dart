part of firebase_storage_plus;

/// Saves [Reference] to queue
/// Won't produce any effect on web
class ReferencePlus {
  ReferencePlus(this.ref);

  final Reference ref;

  /// Deletes data from queue if present and deletes remote data
  /// Might throw an error if reference is still in queue but isn't yet being uploaded
  Future<void> delete() async {
    if (OfflineSyncManager.instance._isInQueue(ref.fullPath) && !kIsWeb) {
      OfflineSyncManager.instance._removeFromQueue(ref);
    } else {
      await ref.delete();
    }
  }

  /// Returns data from queue if present
  /// Otherwise retruns [Reference.getData]
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    assert(maxSize > 0);

    if (OfflineSyncManager.instance._isInQueue(ref.fullPath) && !kIsWeb) {
      return OfflineSyncManager.instance._getLocalFile(ref.fullPath);
    }

    return ref.getData(maxSize);
  }

  /// Returns file uri if ref is queued
  /// Otherwise retruns [Reference.getDownloadURL]
  Future<String> getDownloadURL() async {
    if (OfflineSyncManager.instance._isInQueue(ref.fullPath) && !kIsWeb) {
      try {
        final String localPath =
            OfflineSyncManager.instance._tasks[ref.fullPath]!.localPath;

        return File(localPath).uri.toString();
      } catch (_) {
        return ref.getDownloadURL();
      }
    }

    return ref.getDownloadURL();
  }

  /// Puts data in the queue if [keepInStorage] is true, which is a default value
  /// Otherwise retruns [Reference.putData]
  UploadTask putData(
    Uint8List data, {
    SettableMetadata? metadata,
    bool keepInStorage = true,
  }) {
    if (keepInStorage && !kIsWeb) {
      return OfflineSyncManager.instance._addToQueue(
        bytes: data,
        metadata: _LocalFileMetadata(
          name: ref.name,
          fullPath: ref.fullPath,
          functionName: 'putData',
          timestamp: DateTime.now(),
          settableMetadata: metadata,
        ),
      );
    }

    return ref.putData(data);
  }

  /// Puts file in the queue if [keepInStorage] is true, which is a default value
  /// Otherwise retruns [Reference.putFile]
  UploadTask putFile(
    File file, {
    SettableMetadata? metadata,
    bool keepInStorage = true,
  }) {
    assert(file.absolute.existsSync());

    if (keepInStorage && !kIsWeb) {
      return OfflineSyncManager.instance._addToQueue(
        file: file,
        metadata: _LocalFileMetadata(
          name: ref.name,
          fullPath: ref.fullPath,
          functionName: 'putFile',
          timestamp: DateTime.now(),
          settableMetadata: metadata,
        ),
      );
    }

    return ref.putFile(file);
  }

  /// Puts string in the queue if [keepInStorage] is true, which is a default value
  /// Otherwise retruns [Reference.putString]
  UploadTask putString(
    String data, {
    required bool keepInStorage,
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    if (keepInStorage && !kIsWeb) {
      return OfflineSyncManager.instance._addToQueue(
        stringData: data,
        metadata: _LocalFileMetadata(
          name: ref.name,
          fullPath: ref.fullPath,
          functionName: 'putString',
          timestamp: DateTime.now(),
          settableMetadata: metadata,
          putStringFormat: format,
        ),
      );
    }

    return ref.putString(data);
  }
}
