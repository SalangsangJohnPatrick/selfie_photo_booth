import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as imageLib;

Future<File?> applyFilter(BuildContext context, File imageFile) async {
  final image = imageLib.decodeImage(await imageFile.readAsBytes())!;
  final filteredImage = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PhotoFilterSelector(
        title: Text('Select Filter'),
        image: image,
        filters: presetFiltersList,
      ),
    ),
  );
  return filteredImage != null ? File(filteredImage.path) : null;
}
