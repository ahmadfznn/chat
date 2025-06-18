import 'dart:io';
import 'package:chat/pages/camera_page.dart';
import 'package:chat/pages/image_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class Story extends StatefulWidget {
  const Story({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  _StoryState createState() => _StoryState();
}

class StoryItem {
  final String filePath;
  final String type; // 'image' or 'video'
  final DateTime timestamp;
  StoryItem(
      {required this.filePath, required this.type, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'type': type,
        'timestamp': timestamp.toIso8601String(),
      };
  static StoryItem fromJson(Map<String, dynamic> json) => StoryItem(
        filePath: json['filePath'],
        type: json['type'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class _StoryState extends State<Story> {
  List<StoryItem> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final storyList = prefs.getStringList('stories') ?? [];
    setState(() {
      _stories = storyList
          .map((e) => StoryItem.fromJson(
              Map<String, dynamic>.from(Uri.splitQueryString(e))))
          .toList();
      _loading = false;
    });
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    final storyList =
        _stories.map((e) => Uri(queryParameters: e.toJson()).query).toList();
    await prefs.setStringList('stories', storyList);
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );
    if (result != null) {
      await _uploadStory(result);
      await _loadStories(); // Refresh after upload
    }
  }

  Future<void> _openImagePreview(String imagePath) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ImagePreviewPage(imagePath: imagePath)),
    );
    if (result == true) {
      await _loadStories(); // Refresh after upload from preview
    }
  }

  Future<void> _uploadStory(String filePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 1));
    // Save file locally
    final ext = filePath.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(ext);
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'story_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final newPath = '${appDir.path}/$fileName';
    await File(filePath).copy(newPath);
    final newStory = StoryItem(
      filePath: newPath,
      type: isVideo ? 'video' : 'image',
      timestamp: DateTime.now(),
    );
    setState(() {
      _stories.insert(0, newStory);
    });
    await _saveStories();
    if (mounted) Navigator.pop(context);
    debugPrint("✅ Upload sukses: $newPath");
  }

  void _openStoryViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewer(
          stories: _stories,
          initialIndex: initialIndex,
          profilePhoto: widget.user['photoUrl'] ?? '',
          displayName: widget.user['name'] ?? '',
        ),
      ),
    );
  }

  Widget _buildStoryCircle(StoryItem? story,
      {bool isAdd = false, VoidCallback? onTap, String? label}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          FutureBuilder<Widget>(
            future: _buildPreviewWidget(story, isAdd),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  width: 75,
                  height: 75,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue, width: 4),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return snapshot.data ?? Container();
            },
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Future<Widget> _buildPreviewWidget(StoryItem? story, bool isAdd) async {
    if (isAdd) {
      return Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Icon(IconsaxPlusBold.add_circle, color: Colors.blue, size: 30),
        ),
      );
    }
    if (story == null) {
      return Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Image.asset("assets/img/user.png"),
      );
    }
    if (story.type == 'image') {
      return Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipOval(
          child: Image.file(File(story.filePath), fit: BoxFit.cover, width: 70, height: 70),
        ),
      );
    } else {
      // Video: generate thumbnail
      Uint8List? thumb = await VideoThumbnail.thumbnailData(
        video: story.filePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 70,
        quality: 50,
      );
      return Container(
        width: 75,
        height: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue, width: 4),
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumb != null)
                Image.memory(thumb, fit: BoxFit.cover, width: 70, height: 70),
              Container(
                color: Colors.black26,
                width: 70,
                height: 70,
              ),
              Icon(IconsaxPlusBold.video, color: Colors.blue, size: 30),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: const Color(0xFF2fbffb),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: Icon(IconsaxPlusBold.camera, size: 30),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Add button (always visible)
                      _buildStoryCircle(
                        null,
                        isAdd: true,
                        onTap: _openCamera,
                        label: "Add",
                      ),
                      // Preview of user's story (if exists)
                      if (_stories.isNotEmpty)
                        GestureDetector(
                          onTap: () => _openStoryViewer(0),
                          child: _buildStoryCircle(
                            _stories.first,
                            isAdd: false,
                            label: "My Story",
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_stories.length > 1)
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _stories.length - 1,
                        itemBuilder: (context, idx) {
                          final story = _stories[idx + 1];
                          return GestureDetector(
                            onTap: () => _openStoryViewer(idx + 1),
                            child: _buildStoryCircle(story),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class StoryViewer extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;
  final String? profilePhoto;
  final String? displayName;
  const StoryViewer({super.key, required this.stories, required this.initialIndex, this.profilePhoto, this.displayName});

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideo = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _loadMedia();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    setState(() => _loading = true);
    final story = widget.stories[_currentIndex];
    if (story.type == 'video') {
      _videoController?.dispose();
      _chewieController?.dispose();
      _videoController = VideoPlayerController.file(File(story.filePath));
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );
      _isVideo = true;
    } else {
      _isVideo = false;
    }
    setState(() => _loading = false);
  }

  void _onPageChanged(int idx) async {
    setState(() => _currentIndex = idx);
    await _loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, idx) {
              final s = widget.stories[idx];
              if (s.type == 'image') {
                return Center(
                  child: Image.file(File(s.filePath), fit: BoxFit.contain),
                );
              } else {
                if (_loading ||
                    _videoController == null ||
                    !_videoController!.value.isInitialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Center(
                  child: Chewie(controller: _chewieController!),
                );
              }
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Row(
              children: [
                if (widget.profilePhoto != null && widget.profilePhoto!.isNotEmpty)
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.profilePhoto!),
                    radius: 20,
                  )
                else
                  const CircleAvatar(
                    backgroundImage: AssetImage('assets/img/user.png'),
                    radius: 20,
                  ),
                const SizedBox(width: 10),
                Text(
                  widget.displayName ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Text(
              '${_currentIndex + 1}/${widget.stories.length}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
