import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:chat/services/local_database.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  // Chat personalization
  String fontSize = 'Medium';
  String wallpaperType = 'Default';
  String? wallpaperPath;
  Color? wallpaperColor;
  Color? themeColor;
  // Media & input
  String autoDownload = 'Wi-Fi Only';
  bool enterToSend = true;
  // Notification
  String messageSound = 'Default';
  bool vibration = true;
  // Chat management
  String backupFrequency = 'Never';
  bool loading = true;

  // For demonstration, fake chat list
  final List<Map<String, String>> chats = [
    {'id': '1', 'name': 'Alice'},
    {'id': '2', 'name': 'Bob'},
    {'id': '3', 'name': 'Family Group'},
    {'id': '4', 'name': 'Work Group'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = LocalDatabase.instance;
    final jsonStr = await db.getChatSettings();
    if (jsonStr != null) {
      final data = json.decode(jsonStr);
      setState(() {
        fontSize = data['fontSize'] ?? 'Medium';
        wallpaperType = data['wallpaperType'] ?? 'Default';
        wallpaperPath = data['wallpaperPath'];
        wallpaperColor = data['wallpaperColor'] != null ? Color(data['wallpaperColor']) : null;
        themeColor = data['themeColor'] != null ? Color(data['themeColor']) : null;
        autoDownload = data['autoDownload'] ?? 'Wi-Fi Only';
        enterToSend = data['enterToSend'] ?? true;
        messageSound = data['messageSound'] ?? 'Default';
        vibration = data['vibration'] ?? true;
        backupFrequency = data['backupFrequency'] ?? 'Never';
      });
    }
    setState(() { loading = false; });
  }

  Future<void> _saveSettings() async {
    final db = LocalDatabase.instance;
    final data = {
      'fontSize': fontSize,
      'wallpaperType': wallpaperType,
      'wallpaperPath': wallpaperPath,
      'wallpaperColor': wallpaperColor?.value,
      'themeColor': themeColor?.value,
      'autoDownload': autoDownload,
      'enterToSend': enterToSend,
      'messageSound': messageSound,
      'vibration': vibration,
      'backupFrequency': backupFrequency,
    };
    await db.upsertChatSettings(json.encode(data));
  }

  void _pickWallpaperFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        wallpaperType = 'Gallery';
        wallpaperPath = picked.path;
        wallpaperColor = null;
      });
      _saveSettings();
    }
  }

  void _pickWallpaperColor() async {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.yellow, Colors.teal, Colors.pink, Colors.grey, Colors.black, Colors.white];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick a Color'),
        content: Wrap(
          spacing: 10,
          children: colors.map((c) => GestureDetector(
            onTap: () {
              setState(() {
                wallpaperType = 'Color';
                wallpaperColor = c;
                wallpaperPath = null;
              });
              _saveSettings();
              Navigator.pop(ctx);
            },
            child: CircleAvatar(backgroundColor: c, radius: 18),
          )).toList(),
        ),
      ),
    );
  }

  void _pickThemeColor() async {
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.yellow, Colors.teal, Colors.pink, Colors.grey, Colors.black];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick Theme Color'),
        content: Wrap(
          spacing: 10,
          children: colors.map((c) => GestureDetector(
            onTap: () {
              setState(() { themeColor = c; });
              _saveSettings();
              Navigator.pop(ctx);
            },
            child: CircleAvatar(backgroundColor: c, radius: 18),
          )).toList(),
        ),
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chat Backup'),
        content: Text('Cloud backup/restore is not implemented in this demo.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK'))],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Chat History'),
        content: Text('Clear all chat messages? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () {
            // Here you would clear chat history in the database
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat history cleared.')));
          }, child: Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showArchiveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive Chats'),
        content: Text('Move all chats to archive?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () {
            // Here you would archive chats in the database
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chats archived.')));
          }, child: Text('Archive')),
        ],
      ),
    );
  }

  void _pickMessageSound() async {
    // For demo, just set a fake sound
    setState(() { messageSound = 'Custom'; });
    _saveSettings();
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 18, left: 16, bottom: 6),
    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[700])),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chat Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Color(0xFFf3f4f6),
        leading: IconButton(
          padding: EdgeInsets.all(5),
          icon: Icon(Icons.chevron_left, size: 30, color: Colors.grey[600]),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 25,
        centerTitle: true,
        title: Text("Chat Settings",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: ListView(
        children: [
          // Chat Personalization
          _sectionTitle('Chat Personalization'),
          ListTile(
            title: Text('Font Size'),
            trailing: DropdownButton<String>(
              value: fontSize,
              items: ['Small', 'Medium', 'Large', 'Extra Large'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { fontSize = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Chat Wallpaper'),
            subtitle: Text(wallpaperType == 'Default' ? 'Default Wallpaper' : wallpaperType == 'Gallery' ? 'Custom Image' : 'Solid Color'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.image), onPressed: _pickWallpaperFromGallery),
                IconButton(icon: Icon(Icons.format_color_fill), onPressed: _pickWallpaperColor),
                IconButton(icon: Icon(Icons.refresh), onPressed: () { setState(() { wallpaperType = 'Default'; wallpaperPath = null; wallpaperColor = null; }); _saveSettings(); }),
              ],
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Chat Theme Color'),
            trailing: GestureDetector(
              onTap: _pickThemeColor,
              child: CircleAvatar(backgroundColor: themeColor ?? Colors.blue, radius: 16),
            ),
            tileColor: Colors.white,
          ),
          // Media & Input
          _sectionTitle('Media & Input'),
          ListTile(
            title: Text('Media Auto-Download'),
            trailing: DropdownButton<String>(
              value: autoDownload,
              items: ['Wi-Fi Only', 'Wi-Fi & Mobile Data', 'Never'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { autoDownload = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text('Enter to Send'),
            value: enterToSend,
            onChanged: (v) { setState(() { enterToSend = v; }); _saveSettings(); },
            tileColor: Colors.white,
          ),
          // Chat Management
          _sectionTitle('Chat Management'),
          ListTile(
            title: Text('Chat History Backup'),
            subtitle: Text('Auto Backup: $backupFrequency'),
            trailing: DropdownButton<String>(
              value: backupFrequency,
              items: ['Never', 'Daily', 'Weekly', 'Monthly'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { backupFrequency = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Backup Now'),
            trailing: Icon(Icons.cloud_upload),
            onTap: _showBackupDialog,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Clear Chat History'),
            trailing: Icon(Icons.delete),
            onTap: _showClearHistoryDialog,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Archive Chats'),
            trailing: Icon(Icons.archive),
            onTap: _showArchiveDialog,
            tileColor: Colors.white,
          ),
          // Notification Preferences
          _sectionTitle('Notification Preferences'),
          ListTile(
            title: Text('Message Sound'),
            subtitle: Text(messageSound),
            trailing: Icon(Icons.music_note),
            onTap: _pickMessageSound,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text('Vibration'),
            value: vibration,
            onChanged: (v) { setState(() { vibration = v; }); _saveSettings(); },
            tileColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
