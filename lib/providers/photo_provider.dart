import 'dart:io';
import 'package:flutter/material.dart';
import 'package:selfie_photo_booth/models/photo.dart';

enum BoothLayout {
  vertical, // 4x1
  grid      // 3x2
}

class PhotoProvider with ChangeNotifier {
  List<Photo> _photos = [];
  int _layoutColumns = 4; // Default to 4x1 layout
  bool _isProcessing = false;
  String _boothTheme = 'classic'; // Default theme
  Map<String, dynamic> _filterSettings = {
    'brightness': 1.0,
    'contrast': 1.0,
    'saturation': 1.0,
    'isGrayscale': false,
  };

  // Getters
  List<Photo> get photos => _photos;
  int get layoutColumns => _layoutColumns;
  bool get isProcessing => _isProcessing;
  String get boothTheme => _boothTheme;
  Map<String, dynamic> get filterSettings => _filterSettings;
  
  // Layout helpers
  BoothLayout get layoutType => _layoutColumns == 4 ? BoothLayout.vertical : BoothLayout.grid;
  int get totalPhotosNeeded => _layoutColumns == 4 ? 4 : 6;
  bool get isComplete => _photos.length >= totalPhotosNeeded;
  double get completionPercentage => _photos.isEmpty ? 0.0 : _photos.length / totalPhotosNeeded;

  // Add a photo
  void addPhoto(File image) {
    if (_photos.length < totalPhotosNeeded) {
      _photos.add(Photo(image: image));
      notifyListeners();
    }
  }

  // Remove a photo at specific index
  void removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _photos.removeAt(index);
      notifyListeners();
    }
  }

  // Replace a photo at specific index
  void replacePhoto(int index, File newImage) {
    if (index >= 0 && index < _photos.length) {
      _photos[index] = Photo(image: newImage);
      notifyListeners();
    }
  }

  // Update layout columns (4 for vertical, 3 for grid)
  void updateColumns(int columns) {
    if (columns == 3 || columns == 4) {
      _layoutColumns = columns;
      notifyListeners();
    }
  }

  // Set processing state
  void setProcessing(bool isProcessing) {
    _isProcessing = isProcessing;
    notifyListeners();
  }

  // Update booth theme
  void updateTheme(String theme) {
    _boothTheme = theme;
    notifyListeners();
  }

  // Update filter settings
  void updateFilterSettings(Map<String, dynamic> settings) {
    _filterSettings = {
      ..._filterSettings,
      ...settings,
    };
    notifyListeners();
  }

  // Clear all photos
  void clearPhotos() {
    _photos.clear();
    notifyListeners();
  }

  // Get remaining photos count
  int get remainingPhotos => totalPhotosNeeded - _photos.length;

  // Reorder photos
  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Photo item = _photos.removeAt(oldIndex);
    _photos.insert(newIndex, item);
    notifyListeners();
  }

  // Export photos data for saving
  Map<String, dynamic> exportData() {
    return {
      'layoutColumns': _layoutColumns,
      'theme': _boothTheme,
      'filterSettings': _filterSettings,
      'photosCount': _photos.length,
    };
  }
}