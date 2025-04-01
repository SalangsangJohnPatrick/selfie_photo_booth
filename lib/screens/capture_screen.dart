import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:selfie_photo_booth/providers/photo_provider.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _photosTaken = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    HapticFeedback.mediumImpact();
    _animationController.forward().then((_) => _animationController.reverse());
    
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 90,
    );
    
    if (pickedFile != null) {
      Provider.of<PhotoProvider>(context, listen: false).addPhoto(File(pickedFile.path));
      setState(() {
        _photosTaken++;
      });
    }
    
    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    HapticFeedback.lightImpact();
    
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    
    if (pickedFile != null) {
      Provider.of<PhotoProvider>(context, listen: false).addPhoto(File(pickedFile.path));
      setState(() {
        _photosTaken++;
      });
    }
    
    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = Provider.of<PhotoProvider>(context);
    final total = photoProvider.layoutColumns == 4 ? 4 : 6;
    final remaining = total - _photosTaken;
    final progress = _photosTaken / total;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Capture Photos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3.0,
                color: Color.fromARGB(150, 0, 0, 0),
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.white),
            onPressed: () {
              if (_photosTaken > 0) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Reset Photos?'),
                    content: Text('This will clear all captured photos. Continue?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Provider.of<PhotoProvider>(context, listen: false).clearPhotos();
                          setState(() {
                            _photosTaken = 0;
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Reset', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
              }
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
              SizedBox(height: 16),
              // Photo progress indicator
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Photos: $_photosTaken/$total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          remaining > 0 ? '$remaining more to go' : 'Complete!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              // Preview grid
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildPhotoGrid(photoProvider),
                  ),
                ),
              ),
              // Capture buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: Colors.purple.shade700,
                        onPressed: _pickFromGallery,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: _buildActionButton(
                          icon: Icons.camera_alt,
                          label: 'Take Photo',
                          color: Colors.white,
                          textColor: Colors.pinkAccent,
                          onPressed: _capturePhoto,
                          isMain: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_circle,
                        label: 'Done',
                        color: _photosTaken == total ? Colors.green.shade600 : Colors.grey.shade600,
                        onPressed: _photosTaken == total
                            ? () {
                                // Show completion dialog with preview
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Photos Complete!'),
                                    content: Text('All photos have been captured successfully. Would you like to proceed?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Continue Editing'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pinkAccent,
                                        ),
                                        onPressed: () {
                                          // Navigate to results screen (you'll need to create this)
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: Text('Save & Finish'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback? onPressed,
    bool isMain = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor ?? Colors.white,
        padding: EdgeInsets.symmetric(vertical: isMain ? 16 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isMain ? 8 : 4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMain ? 36 : 24),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 16 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(PhotoProvider photoProvider) {
    final photos = photoProvider.photos;
    final isVertical = photoProvider.layoutColumns == 4;
    final total = isVertical ? 4 : 6;

    if (isVertical) {
      // 4x1 Layout
      return GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 3/4,
          mainAxisSpacing: 12,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          return _buildPhotoCell(
            index < photos.length ? photos[index].image : null,
            index,
          );
        },
      );
    } else {
      // 3x2 Layout
      return GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3/4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          return _buildPhotoCell(
            index < photos.length ? photos[index].image : null,
            index,
          );
        },
      );
    }
  }

  Widget _buildPhotoCell(File? photo, int index) {
    if (photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              photo,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Provider.of<PhotoProvider>(context, listen: false).clearPhotos();
                  setState(() {
                    _photosTaken--;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                color: Colors.grey.shade400,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Photo ${index + 1}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}