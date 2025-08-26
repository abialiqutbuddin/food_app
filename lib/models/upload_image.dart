class UploadImageResponse {
  final String id;
  final String url;

  UploadImageResponse({required this.id, required this.url});

  factory UploadImageResponse.fromJson(Map<String, dynamic> j) => UploadImageResponse(
    id: '${j['id'] ?? j['image_id'] ?? ''}',
    url: j['url']?.toString() ?? '',
  );
}