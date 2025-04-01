import 'dart:io';

class Photo {
  final File image;
  String caption;
  DateTime date;
  String filter;

  Photo({
    required this.image,
    this.caption = '',
    DateTime? date,
    this.filter = '',
  }) : date = date ?? DateTime.now();
}
