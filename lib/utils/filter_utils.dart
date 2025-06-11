import 'package:flutter/material.dart';

// Helper class to define filter properties
class FilterProperties {
  final String name;
  final IconData icon;
  final List<double>? colorMatrix;
  
  FilterProperties({
    required this.name,
    required this.icon,
    this.colorMatrix,
  });
}

class FilterUtils {
  // Available filters with their display names and properties
  static final Map<String, FilterProperties> availableFilters = {
    'Original': FilterProperties(
      name: 'Original',
      icon: Icons.image,
      colorMatrix: null,
    ),
    'Black & White': FilterProperties(
      name: 'Black & White',
      icon: Icons.monochrome_photos,
      colorMatrix: [
        0.2989, 0.5870, 0.1140, 0, 0,
        0.2989, 0.5870, 0.1140, 0, 0,
        0.2989, 0.5870, 0.1140, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Sepia': FilterProperties(
      name: 'Sepia',
      icon: Icons.filter_vintage,
      colorMatrix: [
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Vintage': FilterProperties(
      name: 'Vintage',
      icon: Icons.filter_1,
      colorMatrix: [
        0.9, 0.5, 0.1, 0, 0,
        0.3, 0.8, 0.1, 0, 0,
        0.2, 0.3, 0.5, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Cool': FilterProperties(
      name: 'Cool',
      icon: Icons.ac_unit,
      colorMatrix: [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1.2, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Warm': FilterProperties(
      name: 'Warm',
      icon: Icons.wb_sunny,
      colorMatrix: [
        1.2, 0, 0, 0, 0,
        0, 1.1, 0, 0, 0,
        0, 0, 0.8, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'High Contrast': FilterProperties(
      name: 'High Contrast',
      icon: Icons.contrast,
      colorMatrix: [
        1.5, 0, 0, 0, -0.25,
        0, 1.5, 0, 0, -0.25,
        0, 0, 1.5, 0, -0.25,
        0, 0, 0, 1, 0,
      ],
    ),
    'Dreamy': FilterProperties(
      name: 'Dreamy',
      icon: Icons.cloud,
      colorMatrix: [
        1.1, 0.1, 0.1, 0, 0,
        0.1, 1.1, 0.1, 0, 0,
        0.1, 0.1, 1.1, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Dramatic': FilterProperties(
      name: 'Dramatic',
      icon: Icons.theater_comedy,
      colorMatrix: [
        1.3, 0, 0, 0, 0,
        0, 1.0, 0, 0, 0,
        0, 0, 0.7, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    'Soft': FilterProperties(
      name: 'Soft',
      icon: Icons.blur_on,
      colorMatrix: [
        0.9, 0.1, 0.1, 0, 0.1,
        0.1, 0.9, 0.1, 0, 0.1,
        0.1, 0.1, 0.9, 0, 0.1,
        0, 0, 0, 1, 0,
      ],
    ),
    'Vibrant': FilterProperties(
      name: 'Vibrant',
      icon: Icons.palette,
      colorMatrix: [
        1.4, 0, 0, 0, 0,
        0, 1.4, 0, 0, 0,
        0, 0, 1.4, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
  };

  /// Get all available filter names
  static List<String> getFilterNames() {
    return availableFilters.keys.toList();
  }

  /// Get filter properties by name
  static FilterProperties? getFilterProperties(String filterName) {
    return availableFilters[filterName];
  }

  /// Apply color filter to a widget
  static Widget applyFilterToWidget(Widget child, String filterName) {
    final filterProps = getFilterProperties(filterName);
    
    if (filterProps == null || filterProps.colorMatrix == null) {
      return child; // Return original if no filter or Original filter
    }
    
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(filterProps.colorMatrix!),
      child: child,
    );
  }

  /// Check if filter is the original (no filter)
  static bool isOriginalFilter(String filterName) {
    return filterName == 'Original';
  }

  /// Get filter icon
  static IconData getFilterIcon(String filterName) {
    final filterProps = getFilterProperties(filterName);
    return filterProps?.icon ?? Icons.image;
  }

  /// Get filter display name
  static String getFilterDisplayName(String filterName) {
    final filterProps = getFilterProperties(filterName);
    return filterProps?.name ?? filterName;
  }

  /// Get color matrix for a filter
  static List<double>? getFilterColorMatrix(String filterName) {
    final filterProps = getFilterProperties(filterName);
    return filterProps?.colorMatrix;
  }

  /// Create a preview widget for filter selection
  static Widget buildFilterPreview({
    required String filterName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final filterProps = getFilterProperties(filterName);
    if (filterProps == null) return SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected ? Colors.pinkAccent : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.pinkAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                filterProps.icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ),
            SizedBox(height: 8),
            Text(
              filterProps.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.pinkAccent : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Create color matrix for custom filters
  static List<double> createCustomColorMatrix({
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double hue = 0.0,
  }) {
    // Basic color matrix for custom adjustments
    return [
      contrast, 0, 0, 0, brightness,
      0, contrast, 0, 0, brightness,
      0, 0, contrast, 0, brightness,
      0, 0, 0, 1, 0,
    ];
  }
}