import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'dart:typed_data';
import 'package:chat/components/story_viewer.dart';
import 'package:chat/pages/camera_page.dart';
import 'package:chat/pages/image_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class Story extends StatefulWidget {
  const Story({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  // ignore: library_private_types_in_public_api
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

class _StoryState extends State<Story> with TickerProviderStateMixin {
  List<StoryItem> _stories = [];
  bool _loading = true;
  late AnimationController _pulseController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fabAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStories();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fabAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _onRefresh() async {
    setState(() {});

    await _loadStories();

    setState(() {});
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );
    if (result != null) {
      await _uploadStory(result);
      await _loadStories();
    }
  }

  Future<void> _openImagePreview(String imagePath) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ImagePreviewPage(imagePath: imagePath)),
    );
    if (result == true) {
      await _loadStories();
    }
  }

  Future<void> _uploadStory(String filePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.cloud_upload,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Uploading Story...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                color: Color(0xFF00D4FF),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildMyStoryItem() {
    final hasStory = _stories.isNotEmpty;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: hasStory ? () => _openStoryViewer(0) : _openCamera,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStory
                        ? LinearGradient(
                            colors: [
                              Color.lerp(
                                  const Color(0xFF00D4FF),
                                  const Color(0xFF0099CC),
                                  _pulseAnimation.value)!,
                              Color.lerp(
                                  const Color(0xFF0099CC),
                                  const Color(0xFF00D4FF),
                                  _pulseAnimation.value)!,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF00D4FF), Color(0xFF0099CC)],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF).withOpacity(
                            hasStory ? 0.4 * _pulseAnimation.value : 0.3),
                        blurRadius: hasStory ? 15 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[100],
                      ),
                      child: hasStory
                          ? FutureBuilder<Widget>(
                              future: _buildStoryPreview(_stories.first),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF00D4FF),
                                    ),
                                  );
                                }
                                return snapshot.data ?? Container();
                              },
                            )
                          : Stack(
                              children: [
                                widget.user['photoUrl'] != null
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.user['photoUrl'],
                                          width: 74,
                                          height: 74,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                              "assets/img/user.png",
                                              width: 74,
                                              height: 74,
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      )
                                    : ClipOval(
                                        child: Image.asset(
                                          "assets/img/user.png",
                                          width: 74,
                                          height: 74,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                if (!hasStory)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00D4FF),
                                            Color(0xFF0099CC)
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasStory ? 'My Story' : 'Add Story',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryItem(StoryItem story, int index) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _openStoryViewer(index),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF00D4FF),
                            const Color(0xFF0099CC), _pulseAnimation.value)!,
                        Color.lerp(const Color(0xFF0099CC),
                            const Color(0xFF00D4FF), _pulseAnimation.value)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4FF)
                            .withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: FutureBuilder<Widget>(
                        future: _buildStoryPreview(story),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00D4FF),
                              ),
                            );
                          }
                          return snapshot.data ?? Container();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Story ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Widget> _buildStoryPreview(StoryItem story) async {
    if (story.type == 'image') {
      return ClipOval(
        child: Image.file(
          File(story.filePath),
          width: 74,
          height: 74,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Video: generate thumbnail
      Uint8List? thumb = await VideoThumbnail.thumbnailData(
        video: story.filePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 74,
        quality: 50,
      );
      return ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (thumb != null)
              Image.memory(thumb, fit: BoxFit.cover, width: 74, height: 74),
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Color(0xFF00D4FF),
                size: 16,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00D4FF).withOpacity(0.2)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00D4FF)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFF00D4FF) : Colors.grey[600],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4FF),
                ),
              )
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: const Color(0xFF00D4FF),
                backgroundColor: Colors.white.withOpacity(0.9),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Story Carousel
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _buildMyStoryItem(),
                            ..._stories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final story = entry.value;
                              return _buildStoryItem(story, index);
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                    // Story Feed Section
                    if (_stories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: const Text(
                            'Recent Stories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ),

                    // Story Feed
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildStoryFeedItem(_stories[index], index),
                        childCount: _stories.length,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _fabController.forward(),
        onTapUp: (_) => _fabController.reverse(),
        onTapCancel: () => _fabController.reverse(),
        onTap: _openCamera,
        child: AnimatedBuilder(
          animation: _fabAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabAnimation.value,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF00D4FF),
                      Color(0xFF0099CC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(
                        IconsaxPlusBold.camera,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryFeedItem(StoryItem story, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: widget.user['photoUrl'] != null
                              ? Image.network(
                                  widget.user['photoUrl'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      "assets/img/user.png",
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  "assets/img/user.png",
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user['name'] ?? 'You',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Text(
                              _getTimeAgo(story.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),

                // Story Content
                GestureDetector(
                  onTap: () => _openStoryViewer(index),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D4FF).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: story.type == 'image'
                          ? Image.file(
                              File(story.filePath),
                              fit: BoxFit.cover,
                            )
                          : FutureBuilder<Uint8List?>(
                              future: VideoThumbnail.thumbnailData(
                                video: story.filePath,
                                imageFormat: ImageFormat.JPEG,
                                maxWidth: 400,
                                quality: 75,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF00D4FF),
                                      ),
                                    ),
                                  );
                                }
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (snapshot.hasData)
                                      Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        color: Color(0xFF00D4FF),
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildActionButton(Icons.favorite_border, ''),
                      const SizedBox(width: 24),
                      _buildActionButton(Icons.chat_bubble_outline, ''),
                      const SizedBox(width: 24),
                      _buildActionButton(Icons.share_outlined, ''),
                      const Spacer(),
                      _buildActionButton(Icons.bookmark_border, ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00D4FF).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF00D4FF),
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
