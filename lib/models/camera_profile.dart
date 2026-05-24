class CameraProfile {
  final String id;
  String name;
  int colorIndex;
  String filenameTemplate;
  String storagePath;
  String imageFormat; // 'jpg' | 'png'
  int compressionQuality; // 1-100
  int maxWidth; // 0 = no limit
  int maxHeight;
  bool isDeleted;
  DateTime? deletedAt;
  int photoCount;
  String? wallpaperPath;
  String? dailyDate;
  int dailyCount;
  String? customText;

  CameraProfile({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    this.filenameTemplate = '{相机名}_{日期}_{序号}',
    this.storagePath = '',
    this.imageFormat = 'jpg',
    this.compressionQuality = 95,
    this.maxWidth = 0,
    this.maxHeight = 0,
    this.isDeleted = false,
    this.deletedAt,
    this.photoCount = 0,
    this.wallpaperPath,
    this.dailyDate,
    this.dailyCount = 0,
    this.customText,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'filenameTemplate': filenameTemplate,
        'storagePath': storagePath,
        'imageFormat': imageFormat,
        'compressionQuality': compressionQuality,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'isDeleted': isDeleted ? 1 : 0,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
        'photoCount': photoCount,
        'wallpaperPath': wallpaperPath,
        'dailyDate': dailyDate,
        'dailyCount': dailyCount,
        'customText': customText,
      };

  factory CameraProfile.fromMap(Map<String, dynamic> map) => CameraProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        colorIndex: map['colorIndex'] as int? ?? 0,
        filenameTemplate:
            map['filenameTemplate'] as String? ?? '{相机名}_{日期}_{序号}',
        storagePath: map['storagePath'] as String? ?? '',
        imageFormat: map['imageFormat'] as String? ?? 'jpg',
        compressionQuality: map['compressionQuality'] as int? ?? 95,
        maxWidth: map['maxWidth'] as int? ?? 0,
        maxHeight: map['maxHeight'] as int? ?? 0,
        isDeleted: (map['isDeleted'] as int? ?? 0) == 1,
        deletedAt: map['deletedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int)
            : null,
        photoCount: map['photoCount'] as int? ?? 0,
        wallpaperPath: map['wallpaperPath'] as String?,
        dailyDate: map['dailyDate'] as String?,
        dailyCount: map['dailyCount'] as int? ?? 0,
        customText: map['customText'] as String?,
      );

  CameraProfile copyWith({
    String? name,
    int? colorIndex,
    String? filenameTemplate,
    String? storagePath,
    String? imageFormat,
    int? compressionQuality,
    int? maxWidth,
    int? maxHeight,
    bool? isDeleted,
    DateTime? deletedAt,
    int? photoCount,
    String? wallpaperPath,
    String? dailyDate,
    int? dailyCount,
    String? customText,
  }) =>
      CameraProfile(
        id: id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        filenameTemplate: filenameTemplate ?? this.filenameTemplate,
        storagePath: storagePath ?? this.storagePath,
        imageFormat: imageFormat ?? this.imageFormat,
        compressionQuality: compressionQuality ?? this.compressionQuality,
        maxWidth: maxWidth ?? this.maxWidth,
        maxHeight: maxHeight ?? this.maxHeight,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt ?? this.deletedAt,
        photoCount: photoCount ?? this.photoCount,
        wallpaperPath: wallpaperPath ?? this.wallpaperPath,
        dailyDate: dailyDate ?? this.dailyDate,
        dailyCount: dailyCount ?? this.dailyCount,
        customText: customText ?? this.customText,
      );
}
