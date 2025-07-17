import 'package:chat/features/story/presentation/pages/story.dart';
import 'package:flutter/material.dart';

class StoryViewer extends StatelessWidget {
  final List<StoryItem> stories;
  final int initialIndex;
  final String profilePhoto;
  final String displayName;

  const StoryViewer({
    super.key,
    required this.stories,
    required this.initialIndex,
    required this.profilePhoto,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Story Viewer Placeholder',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
