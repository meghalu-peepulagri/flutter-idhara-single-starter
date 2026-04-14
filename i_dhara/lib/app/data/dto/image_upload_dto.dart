class ImageUploadDto {
  final String fileName;
  final String fileType;
  final String fileBase64;

  ImageUploadDto({
    required this.fileName,
    required this.fileType,
    required this.fileBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'file_type': fileType,
      'file': fileBase64,
    };
  }

  factory ImageUploadDto.fromJson(Map<String, dynamic> json) {
    return ImageUploadDto(
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileBase64: json['file'] ?? '',
    );
  }
}
