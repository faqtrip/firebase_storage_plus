part of firebase_storage_plus;

/// Contains info on a queued task
class QueuedTaskInfo {
  ///
  QueuedTaskInfo({
    required this.ref,
    required this.task,
    required this.localPath,
  });

  // ignore: prefer_final_fields
  double _progress = 0;

  /// Progress of upload from 0 to 1
  double get progress => _progress;

  /// [Reference] that initiated the task
  final Reference ref;

  /// [UploadTask] that was initiated
  final UploadTask task;

  /// Local path of the file
  final String localPath;
}
