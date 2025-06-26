import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:chat/services/local_database.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  PrivacyPageState createState() => PrivacyPageState();
}

class PrivacyPageState extends State<PrivacyPage> {
  // Visibility controls
  String lastSeen = 'Everyone';
  String profilePhoto = 'Everyone';
  String about = 'Everyone';
  bool readReceipts = true;
  // Interaction controls
  List<Map<String, dynamic>> blockedContacts = [];
  String groupPrivacy = 'Everyone';
  // Security
  bool appLockEnabled = false;
  String? pin;
  // Data usage
  String autoDownload = 'Wi-Fi Only';
  // Loading state
  bool loading = true;

  // For demonstration, fake contacts
  final List<Map<String, String>> contacts = [
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
    final jsonStr = await db.getPrivacySettings();
    final blocked = await db.getBlockedContacts();
    if (jsonStr != null) {
      final data = json.decode(jsonStr);
      setState(() {
        lastSeen = data['lastSeen'] ?? 'Everyone';
        profilePhoto = data['profilePhoto'] ?? 'Everyone';
        about = data['about'] ?? 'Everyone';
        readReceipts = data['readReceipts'] ?? true;
        groupPrivacy = data['groupPrivacy'] ?? 'Everyone';
        appLockEnabled = data['appLockEnabled'] ?? false;
        pin = data['pin'];
        autoDownload = data['autoDownload'] ?? 'Wi-Fi Only';
      });
    }
    setState(() { blockedContacts = blocked; loading = false; });
  }

  Future<void> _saveSettings() async {
    final db = LocalDatabase.instance;
    final data = {
      'lastSeen': lastSeen,
      'profilePhoto': profilePhoto,
      'about': about,
      'readReceipts': readReceipts,
      'groupPrivacy': groupPrivacy,
      'appLockEnabled': appLockEnabled,
      'pin': pin,
      'autoDownload': autoDownload,
    };
    await db.upsertPrivacySettings(json.encode(data));
  }

  void _showBlockedContactsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Blocked Contacts'),
        content: Container(
          width: 300,
          child: blockedContacts.isEmpty
              ? Text('No blocked contacts.')
              : ListView(
                  shrinkWrap: true,
                  children: blockedContacts.map((c) => ListTile(
                    title: Text(c['name'] ?? ''),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await LocalDatabase.instance.unblockContact(c['id']);
                        Navigator.pop(ctx);
                        _loadSettings();
                      },
                    ),
                  )).toList(),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
        ],
      ),
    );
  }

  void _showAddBlockDialog() {
    String? selectedId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block Contact'),
        content: DropdownButtonFormField<String>(
          items: contacts.map((c) => DropdownMenuItem(
            value: c['id'],
            child: Text(c['name'] ?? ''),
          )).toList(),
          onChanged: (v) { selectedId = v; },
          decoration: InputDecoration(hintText: 'Select contact'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () async {
            if (selectedId != null) {
              final name = contacts.firstWhere((c) => c['id'] == selectedId)['name'] ?? '';
              await LocalDatabase.instance.blockContact(selectedId!, name);
              Navigator.pop(ctx);
              _loadSettings();
            }
          }, child: Text('Block')),
        ],
      ),
    );
  }

  void _showPinDialog() {
    String newPin = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set App Lock PIN'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          onChanged: (v) => newPin = v,
          decoration: InputDecoration(hintText: 'Enter 4-6 digit PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () async {
            if (newPin.length >= 4) {
              setState(() { pin = newPin; appLockEnabled = true; });
              await _saveSettings();
              Navigator.pop(ctx);
            }
          }, child: Text('Save')),
        ],
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

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Messages: 12 MB'),
            Text('Media: 45 MB'),
            Text('Cache: 8 MB'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); },
              child: Text('Clear Cache'),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close'))],
      ),
    );
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 18, left: 16, bottom: 6),
    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[700])),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Privacy Settings')),
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
        title: Text("Privacy",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: ListView(
        children: [
          // Visibility Controls
          _sectionTitle('Who Can See My Info'),
          ListTile(
            title: Text('Last Seen & Online Status'),
            trailing: DropdownButton<String>(
              value: lastSeen,
              items: ['Everyone', 'My Contacts', 'Nobody'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { lastSeen = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Profile Photo Visibility'),
            trailing: DropdownButton<String>(
              value: profilePhoto,
              items: ['Everyone', 'My Contacts', 'Nobody'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { profilePhoto = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('About Info/Status Visibility'),
            trailing: DropdownButton<String>(
              value: about,
              items: ['Everyone', 'My Contacts', 'Nobody'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { about = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text('Read Receipts (Blue Ticks)'),
            value: readReceipts,
            onChanged: (v) { setState(() { readReceipts = v; }); _saveSettings(); },
            tileColor: Colors.white,
          ),
          // Interaction Controls
          _sectionTitle('Interaction Controls'),
          ListTile(
            title: Text('Blocked Contacts'),
            subtitle: Text(blockedContacts.isEmpty ? 'No blocked contacts' : blockedContacts.map((c) => c['name']).join(', ')),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.list), onPressed: _showBlockedContactsDialog),
                IconButton(icon: Icon(Icons.person_add_disabled), onPressed: _showAddBlockDialog),
              ],
            ),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Who Can Add Me to Groups'),
            trailing: DropdownButton<String>(
              value: groupPrivacy,
              items: ['Everyone', 'My Contacts', 'Nobody'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { groupPrivacy = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          // Security & Data Management
          _sectionTitle('Security & Data Management'),
          SwitchListTile(
            title: Text('App Lock (PIN/Biometric)'),
            value: appLockEnabled,
            onChanged: (v) {
              setState(() { appLockEnabled = v; });
              if (v) _showPinDialog();
              else { pin = null; _saveSettings(); }
            },
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Change PIN'),
            enabled: appLockEnabled,
            trailing: Icon(Icons.lock),
            onTap: appLockEnabled ? _showPinDialog : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Chat Backup & Restore'),
            trailing: Icon(Icons.cloud_upload),
            onTap: _showBackupDialog,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Data Usage & Storage'),
            trailing: Icon(Icons.storage),
            onTap: _showStorageDialog,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Auto-download Media'),
            trailing: DropdownButton<String>(
              value: autoDownload,
              items: ['Wi-Fi Only', 'Mobile Data', 'Never'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) { setState(() { autoDownload = v!; }); _saveSettings(); },
            ),
            tileColor: Colors.white,
          ),
          // Legal & Info
          _sectionTitle('Legal & Information'),
          ListTile(
            title: Text('Privacy Policy'),
            trailing: Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://yourapp.com/privacy'),
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Terms of Service'),
            trailing: Icon(Icons.open_in_new),
            onTap: () => _launchUrl('https://yourapp.com/terms'),
            tileColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
