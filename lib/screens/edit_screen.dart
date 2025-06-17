import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:selfix/providers/photo_provider.dart';
import 'package:selfix/models/photo.dart';
import 'package:selfix/utils/filter_utils.dart';
import 'package:selfix/utils/border_utils.dart';
import 'package:selfix/utils/caption_utils.dart';

class EditScreen extends StatefulWidget {
  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _captionController = TextEditingController();
  Color _selectedBorderColor = Colors.white;
  late AnimationController _animationController;
  bool _isSaving = false;
  String _selectedFilter = 'Original';
  int _currentTabIndex = 0;
  int _selectedCaptionStyleIndex = 0;

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

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      var status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      var status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> _saveLayout() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      bool granted = await requestStoragePermission();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied to save image.')),
        );
        return;
      }

      // Capture widget image
      RenderRepaintBoundary boundary =
          _previewKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file =
          await File(
            '${tempDir.path}/selfix_${DateTime.now().millisecondsSinceEpoch}.png',
          ).create();
      await file.writeAsBytes(pngBytes);

      // Initialize MediaStore
      await MediaStore.ensureInitialized();

      MediaStore.appFolder = "Selfix";

      // Save the image to Pictures/Selfix
      await MediaStore().saveFile(
        tempFilePath: file.path,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to gallery!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
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
                builder:
                    (context) => Container(
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
                          _buildTipItem(
                            Icons.filter,
                            'Use Filters tab to apply aesthetic filters to all photos',
                          ),
                          _buildTipItem(
                            Icons.border_color,
                            'Use Border tab to choose a border color',
                          ),
                          _buildTipItem(
                            Icons.text_fields,
                            'Use Caption tab to add text to your layout',
                          ),
                          _buildTipItem(
                            Icons.save_alt,
                            'Tap Export when you\'re ready to save',
                          ),
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
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: InteractiveViewer(
                              minScale: 0.3,
                              maxScale: 4.0,
                              boundaryMargin: EdgeInsets.all(80),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: RepaintBoundary(
                                    key: _previewKey,
                                    child: Container(
                                      width:
                                          320, // fixed logical size for preview
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Photos grid
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _selectedBorderColor,
                                            ),
                                            child: SizedBox(
                                              child: _buildPhotoGrid(
                                                photos,
                                                isVertical,
                                              ),
                                            ),
                                          ),
                                          // Caption area
                                          Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  captionStyles[_selectedCaptionStyleIndex]
                                                      .backgroundColor,
                                            ),
                                            child:
                                                _captionController
                                                        .text
                                                        .isNotEmpty
                                                    ? Text(
                                                      _captionController.text,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style:
                                                          captionStyles[_selectedCaptionStyleIndex]
                                                              .textStyle,
                                                    )
                                                    : SizedBox(height: 20),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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
                  icon:
                      _isSaving
                          ? Container(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
                  onPressed:
                      (_isSaving || photoProvider.isProcessing)
                          ? null
                          : _saveLayout,
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
      bottomSheet: _currentTabIndex == -1 ? null : _buildBottomSheet(),
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
          Icon(icon, color: isSelected ? Colors.pinkAccent : Colors.grey),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                final filterName = FilterUtils.availableFilters.keys.elementAt(
                  index,
                );
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: borderColors.length,
              itemBuilder: (context, index) {
                final color = borderColors[index];
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
                      boxShadow:
                          isSelected
                              ? [BoxShadow(color: Colors.black26)]
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
      height: 200,
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              hintText: 'Enter your caption here...',
              prefixIcon: Icon(Icons.text_fields),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          SizedBox(height: 12),
          Text(
            'Caption Style',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: captionStyles.length,
              separatorBuilder: (_, __) => SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final style = captionStyles[idx];
                final selected = idx == _selectedCaptionStyleIndex;
                return ChoiceChip(
                  label: Text(
                    style.name,
                    style: style.textStyle.copyWith(fontSize: 14),
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCaptionStyleIndex = idx;
                    });
                  },
                  selectedColor: Colors.pinkAccent.withOpacity(0.2),
                  backgroundColor: Colors.grey.shade200,
                );
              },
            ),
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
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
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
      // Show all photos in a vertical column
      return Column(
        mainAxisSize: MainAxisSize.min,
        children:
            photos
                .map(
                  (photo) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: AspectRatio(
                      aspectRatio: 3 / 2,
                      child: _buildPhotoCell(
                        photo.image,
                        photos.indexOf(photo),
                      ),
                    ),
                  ),
                )
                .toList(),
      );
    } else {
      // Show all photos in a 2-column grid using Wrap
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        children:
            photos
                .map(
                  (photo) => SizedBox(
                    width: 140,
                    height: 180,
                    child: _buildPhotoCell(photo.image, photos.indexOf(photo)),
                  ),
                )
                .toList(),
      );
    }
  }

  Widget _buildPhotoCell(File photo, int index) {
    Widget photoWidget = Image.file(photo, fit: BoxFit.cover);

    // Apply filter using FilterUtils
    photoWidget = FilterUtils.applyFilterToWidget(photoWidget, _selectedFilter);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: photoWidget,
      ),
    );
  }
}
