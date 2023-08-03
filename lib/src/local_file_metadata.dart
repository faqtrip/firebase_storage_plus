part of firebase_storage_plus;

/// A model containing info on a document to be stored in a queue and uploaded
class _LocalFileMetadata {
  // ignore: public_member_api_docs
  const _LocalFileMetadata({
    required this.name,
    required this.fullPath,
    this.settableMetadata,
    this.putStringFormat,
    required this.functionName,
    required this.timestamp,
  });

  final String name;

  final String fullPath;

  final SettableMetadata? settableMetadata;

  final PutStringFormat? putStringFormat;

  final String functionName;

  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'name': name,
        'fullPath': fullPath,
        'metadata': settableMetadata?.asMap(),
        'putStringFormat': putStringFormat,
        'functionName': functionName,
        'timestamp': timestamp.toIso8601String(),
      };

  static _LocalFileMetadata fromJson(Map<String, dynamic> json) {
    return _LocalFileMetadata(
      name: json['name'],
      fullPath: json['fullPath'],
      settableMetadata: SettableMetadata(
        cacheControl: json['metadata']?['cacheControl'],
        contentDisposition: json['metadata']?['contentDisposition'],
        contentEncoding: json['metadata']?['contentEncoding'],
        contentLanguage: json['metadata']?['contentLanguage'],
        contentType: json['metadata']?['contentType'],
        customMetadata: json['metadata']?['customMetadata'],
      ),
      putStringFormat: json['putStringFormat'],
      functionName: json['functionName'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  String get localFileName => timestamp.toIso8601String() + name;
}
