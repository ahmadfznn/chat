import 'package:flutter/material.dart';
import 'dart:io';

class FullScreenImageViewer extends StatefulWidget {
  const FullScreenImageViewer({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  // ignore: library_private_types_in_public_api
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  // double _verticalDrag = 0.0;

  // void _onVerticalDragUpdate(DragUpdateDetails details) {
  //   setState(() {
  //     _verticalDrag += details.primaryDelta!;
  //   });
  // }

  // void _onVerticalDragEnd(DragEndDetails details) {
  //   setState(() {
  //     _verticalDrag = 0;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 10.0,
          clipBehavior: Clip.none,
          child: widget.imageUrl.startsWith('http')
              ? Image.network(widget.imageUrl)
              : Image.file(File(widget.imageUrl)),
        ),
      ),
    );
  }
}
