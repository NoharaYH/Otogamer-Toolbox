class ChuMusic {
  final int id;
  final String title;
  final String artist;

  ChuMusic({required this.id, required this.title, required this.artist});

  factory ChuMusic.fromJson(Map<String, dynamic> json) =>
      ChuMusic(id: json['id'], title: json['title'], artist: json['artist']);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'artist': artist};
}
