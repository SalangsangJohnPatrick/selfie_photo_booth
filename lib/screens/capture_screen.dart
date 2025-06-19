import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:selfix/providers/photo_provider.dart';
import 'package:selfix/screens/edit_screen.dart';

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late PhotoProvider photoProvider;
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    photoProvider = Provider.of<PhotoProvider>(context);
    _photosTaken = photoProvider.photos.length;
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
      Provider.of<PhotoProvider>(
        context,
        listen: false,
      ).addPhoto(File(pickedFile.path));
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
      Provider.of<PhotoProvider>(
        context,
        listen: false,
      ).addPhoto(File(pickedFile.path));
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
    final remaining = photoProvider.remainingPhotos;
    final progress = photoProvider.completionPercentage;

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
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Provider.of<PhotoProvider>(context, listen: false).clearPhotos();
            setState(() {
              _photosTaken = 0;
            });
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.white),
            onPressed: () {
              if (_photosTaken > 0) {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Reset Photos?'),
                        content: Text(
                          'This will clear all captured photos. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Provider.of<PhotoProvider>(
                                context,
                                listen: false,
                              ).clearPhotos();
                              setState(() {
                                _photosTaken = 0;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(color: Colors.redAccent),
                            ),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
              // Redesigned capture buttons section
              _buildCaptureButtonsSection(total),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButtonsSection(int total) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Main container with side buttons
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button
              _buildSideButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.purple.shade600,
                onPressed: _photosTaken < total ? _pickFromGallery : null,
              ),

              // Spacer for the circular button
              SizedBox(width: 80),

              // Done button
              _buildSideButton(
                icon: Icons.check_circle,
                label: 'Done',
                color:
                    _photosTaken == total
                        ? Colors.green.shade600
                        : Colors.grey.shade400,
                onPressed:
                    _photosTaken == total
                        ? () {
                          // Show completion dialog with preview
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: Text('Photos Complete!'),
                                  content: Text(
                                    'All photos have been captured successfully. Would you like to proceed?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Continue Capturing',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.pinkAccent,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Proceed to Edit',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }
                        : null,
              ),
            ],
          ),
        ),

        // Circular Take Photo button positioned above
        Positioned(
          top: -10,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: GestureDetector(
              onTap: _photosTaken < total ? _capturePhoto : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        _photosTaken < total
                            ? [
                              Colors.pinkAccent.shade200,
                              Colors.pinkAccent.shade400,
                            ]
                            : [Colors.grey.shade300, Colors.grey.shade500],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          _photosTaken < total
                              ? Colors.pinkAccent.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(Icons.camera_alt, size: 32, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              onPressed != null ? color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                onPressed != null
                    ? color.withOpacity(0.3)
                    : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: onPressed != null ? color : Colors.grey.shade400,
            ),
            SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onPressed != null ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
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
          childAspectRatio: 3 / 4,
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
          childAspectRatio: 3 / 4,
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
            Image.file(photo, fit: BoxFit.cover),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  Provider.of<PhotoProvider>(
                    context,
                    listen: false,
                  ).removePhoto(index);
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
                  child: Icon(Icons.close, color: Colors.white, size: 16),
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
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, color: Colors.grey.shade400, size: 36),
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
