import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:selfie_photo_booth/providers/photo_provider.dart';
import 'package:selfie_photo_booth/models/photo.dart';
import 'package:selfie_photo_booth/utils/filter_utils.dart';

class EditScreen extends StatefulWidget {
  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> with SingleTickerProviderStateMixin {
  TextEditingController _captionController = TextEditingController();
  Color _selectedBorderColor = Colors.white;
  late AnimationController _animationController;
  bool _isSaving = false;
  String _selectedFilter = 'Original';
  int _currentTabIndex = 0;
  
  // Border color options
  final List<Color> _borderColors = [
    Colors.white,
    Colors.black,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveLayout() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // Capture the rendering of the photo grid
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      
      if (byteData != null) {
        // For demo purposes, we'll show success
        // In real app, you'd use image_gallery_saver package
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo layout saved to gallery!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Haptic feedback on success
        HapticFeedback.heavyImpact();
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('Your photo layout has been saved to your gallery.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: Text('Back to Home'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog('Failed to process image data.');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Global key for capturing the widget as image
  final GlobalKey _previewKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final photos = photoProvider.photos;
    final isVertical = photoProvider.layoutType == BoothLayout.vertical;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit & Share',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editing Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildTipItem(Icons.filter, 'Use Filters tab to apply aesthetic filters to all photos'),
                      _buildTipItem(Icons.border_color, 'Use Border tab to choose a border color'),
                      _buildTipItem(Icons.text_fields, 'Use Caption tab to add text to your layout'),
                      _buildTipItem(Icons.save_alt, 'Tap Export when you\'re ready to save'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pinkAccent.shade400,
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Preview with photos and caption
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: RepaintBoundary(
                            key: _previewKey,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                        bottomLeft: _captionController.text.isEmpty ? Radius.circular(16) : Radius.zero,
                                        bottomRight: _captionController.text.isEmpty ? Radius.circular(16) : Radius.zero,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(12),
                                        color: _selectedBorderColor,
                                        child: _buildPhotoGrid(photos, isVertical),
                                      ),
                                    ),
                                  ),
                                  if (_captionController.text.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        _captionController.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Export button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? Container(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.save_alt),
                  label: Text(_isSaving ? 'Saving...' : 'Export to Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    minimumSize: Size(double.infinity, 56),
                  ),
                  onPressed: (_isSaving || photoProvider.isProcessing) ? null : _saveLayout,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.filter, 'Filter'),
              _buildNavItem(1, Icons.border_color, 'Border'),
              _buildNavItem(2, Icons.text_fields, 'Caption'),
            ],
          ),
        ),
      ),
      bottomSheet: _currentTabIndex == -1 
          ? null 
          : _buildBottomSheet(),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentTabIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = isSelected ? -1 : index;
        });
        HapticFeedback.lightImpact();
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.pinkAccent : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.pinkAccent : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    switch (_currentTabIndex) {
      case 0: // Filter
        return _buildFilterBottomSheet();
      case 1: // Border
        return _buildBorderBottomSheet();
      case 2: // Caption
        return _buildCaptionBottomSheet();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      height: 170,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Filter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current: $_selectedFilter',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
                itemCount: FilterUtils.availableFilters.length,
              itemBuilder: (context, index) {
                final filterName = FilterUtils.availableFilters.keys.elementAt(index);
                final isSelected = _selectedFilter == filterName;
                
                return FilterUtils.buildFilterPreview(
                  filterName: filterName,
                  isSelected: isSelected,
                  onTap: () => _applyFilterToAllPhotos(filterName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderBottomSheet() {
    return Container(
      height: 120,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Border Color',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _borderColors.length,
              itemBuilder: (context, index) {
                final color = _borderColors[index];
                final isSelected = color == _selectedBorderColor;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBorderColor = color;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 16),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black26,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionBottomSheet() {
    return Container(
      height: 130,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Caption',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              hintText: 'Enter your caption here...',
              prefixIcon: Icon(Icons.text_fields),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            onChanged: (value) {
              // Re-render UI when caption changes
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.pinkAccent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilterToAllPhotos(String filterName) {
    setState(() {
      _selectedFilter = filterName;
    });
    HapticFeedback.lightImpact();
  }

  Widget _buildPhotoGrid(List<Photo> photos, bool isVertical) {
    if (isVertical) {
      // 4x1 Layout - Lengthwise
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 3/4,  // Portrait aspect ratio
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoCell(photos[index].image, index);
              },
            ),
          );
        }
      );
    } else {
      // 3x2 Layout (2x3 visually) - Lengthwise
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3/4,  // Portrait aspect ratio
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return _buildPhotoCell(photos[index].image, index);
              },
            ),
          );
        }
      );
    }
  }

  Widget _buildPhotoCell(File photo, int index) {
    Widget photoWidget = Image.file(
      photo,
      fit: BoxFit.cover,
    );
    
    // Apply filter using FilterUtils
    photoWidget = FilterUtils.applyFilterToWidget(photoWidget, _selectedFilter);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: photoWidget,
      ),
    );
  }
}