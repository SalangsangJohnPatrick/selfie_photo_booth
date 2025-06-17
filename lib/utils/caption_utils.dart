import 'package:flutter/material.dart';

// Caption style options
final List<CaptionStyle> captionStyles = [
  CaptionStyle(
    name: 'Default',
    textStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    ),
    backgroundColor: Colors.white,
  ),
  CaptionStyle(
    name: 'Bold Pink',
    textStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.pinkAccent,
    ),
    backgroundColor: Colors.white,
  ),
  CaptionStyle(
    name: 'White on Black',
    textStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    backgroundColor: Colors.black87,
  ),
  CaptionStyle(
    name: 'Blue Italic',
    textStyle: TextStyle(
      fontSize: 20,
      fontStyle: FontStyle.italic,
      color: Colors.blueAccent,
    ),
    backgroundColor: Colors.white,
  ),
];

class CaptionStyle {
  final String name;
  final TextStyle textStyle;
  final Color backgroundColor;

  const CaptionStyle({
    required this.name,
    required this.textStyle,
    required this.backgroundColor,
  });
}