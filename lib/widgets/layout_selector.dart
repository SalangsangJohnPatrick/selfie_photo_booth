import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:selfix/providers/photo_provider.dart';

class LayoutSelector extends StatefulWidget {
  @override
  _LayoutSelectorState createState() => _LayoutSelectorState();
}

class _LayoutSelectorState extends State<LayoutSelector> with SingleTickerProviderStateMixin {
  bool isFirstLayoutSelected = true;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLayoutOption(
          isSelected: isFirstLayoutSelected,
          title: '4x1 Layout',
          onSelect: () {
            setState(() {
              isFirstLayoutSelected = true;
            });
            Provider.of<PhotoProvider>(context, listen: false).updateColumns(4);
          },
          previewBuilder: (isSelected) => _buildLayoutPreview(
            isSelected: isSelected,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) => _buildPreviewPhoto()),
            ),
          ),
        ),
        SizedBox(width: 20),
        _buildLayoutOption(
          isSelected: !isFirstLayoutSelected,
          title: '3x2 Layout',
          onSelect: () {
            setState(() {
              isFirstLayoutSelected = false;
            });
            Provider.of<PhotoProvider>(context, listen: false).updateColumns(3);
          },
          previewBuilder: (isSelected) => _buildLayoutPreview(
            isSelected: isSelected,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPreviewPhoto(),
                    _buildPreviewPhoto(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPreviewPhoto(),
                    _buildPreviewPhoto(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPreviewPhoto(),
                    _buildPreviewPhoto(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutOption({
    required bool isSelected,
    required String title,
    required VoidCallback onSelect,
    required Widget Function(bool isSelected) previewBuilder,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        onSelect();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 150,
          height: 240,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.pinkAccent : Colors.transparent,
              width: 3,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.pinkAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              previewBuilder(isSelected),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pinkAccent : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayoutPreview({required Widget child, required bool isSelected}) {
    return Container(
      width: 120,
      height: 160,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.pinkAccent.withOpacity(0.3) : Colors.grey.shade300,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPreviewPhoto() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Icon(
        Icons.person,
        color: Colors.grey.shade600,
        size: 16,
      ),
    );
  }
}