import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat/services/local_database.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Notification settings state
  bool notifAll = true;
  bool notifPersonal = true;
  bool notifGroup = true;
  bool previewPersonal = true;
  bool previewGroup = true;
  Map<String, bool> specialVibes = {}; // contactId/groupId: bool
  List<String> priorityContacts = [];
  bool personalMode = false;
  TimeOfDay? personalModeStart;
  TimeOfDay? personalModeEnd;
  bool personalModeAuto = false;
  bool dndMode = false;
  TimeOfDay? dndStart;
  TimeOfDay? dndEnd;
  List<String> dndExceptions = [];
  bool smartNotif = false;
  List<String> smartKeywords = [];
  Color? notifIconColor;
  Color? notifLedColor;
  Map<String, String> customSounds = {}; // contactId/groupId: path
  bool fastReply = true;
  bool fastMarkRead = true;

  bool loading = true;

  // For demonstration, fake contacts/groups
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
    final jsonStr = await db.getNotificationSettings();
    if (jsonStr != null) {
      final data = json.decode(jsonStr);
      setState(() {
        notifAll = data['notifAll'] ?? true;
        notifPersonal = data['notifPersonal'] ?? true;
        notifGroup = data['notifGroup'] ?? true;
        previewPersonal = data['previewPersonal'] ?? true;
        previewGroup = data['previewGroup'] ?? true;
        specialVibes = Map<String, bool>.from(data['specialVibes'] ?? {});
        priorityContacts = List<String>.from(data['priorityContacts'] ?? []);
        personalMode = data['personalMode'] ?? false;
        personalModeStart = _parseTime(data['personalModeStart']);
        personalModeEnd = _parseTime(data['personalModeEnd']);
        personalModeAuto = data['personalModeAuto'] ?? false;
        dndMode = data['dndMode'] ?? false;
        dndStart = _parseTime(data['dndStart']);
        dndEnd = _parseTime(data['dndEnd']);
        dndExceptions = List<String>.from(data['dndExceptions'] ?? []);
        smartNotif = data['smartNotif'] ?? false;
        smartKeywords = List<String>.from(data['smartKeywords'] ?? []);
        notifIconColor = _parseColor(data['notifIconColor']);
        notifLedColor = _parseColor(data['notifLedColor']);
        customSounds = Map<String, String>.from(data['customSounds'] ?? {});
        fastReply = data['fastReply'] ?? true;
        fastMarkRead = data['fastMarkRead'] ?? true;
      });
    }
    setState(() { loading = false; });
  }

  Future<void> _saveSettings() async {
    final db = LocalDatabase.instance;
    final data = {
      'notifAll': notifAll,
      'notifPersonal': notifPersonal,
      'notifGroup': notifGroup,
      'previewPersonal': previewPersonal,
      'previewGroup': previewGroup,
      'specialVibes': specialVibes,
      'priorityContacts': priorityContacts,
      'personalMode': personalMode,
      'personalModeStart': _timeToString(personalModeStart),
      'personalModeEnd': _timeToString(personalModeEnd),
      'personalModeAuto': personalModeAuto,
      'dndMode': dndMode,
      'dndStart': _timeToString(dndStart),
      'dndEnd': _timeToString(dndEnd),
      'dndExceptions': dndExceptions,
      'smartNotif': smartNotif,
      'smartKeywords': smartKeywords,
      'notifIconColor': notifIconColor?.value,
      'notifLedColor': notifLedColor?.value,
      'customSounds': customSounds,
      'fastReply': fastReply,
      'fastMarkRead': fastMarkRead,
    };
    await db.upsertNotificationSettings(json.encode(data));
  }

  TimeOfDay? _parseTime(dynamic t) {
    if (t == null) return null;
    if (t is String && t.contains(':')) {
      final parts = t.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return null;
  }

  String? _timeToString(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour}:${t.minute}';
  }

  Color? _parseColor(dynamic v) {
    if (v == null) return null;
    return Color(v);
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay? initial, Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial ?? TimeOfDay.now());
    if (picked != null) onPicked(picked);
  }

  void _showAddKeywordDialog() {
    String keyword = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Keyword'),
        content: TextField(
          autofocus: true,
          onChanged: (v) => keyword = v,
          decoration: InputDecoration(hintText: 'e.g. urgent'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () {
            if (keyword.trim().isNotEmpty) {
              setState(() { smartKeywords.add(keyword.trim()); });
              _saveSettings();
            }
            Navigator.pop(ctx);
          }, child: Text('Add')),
        ],
      ),
    );
  }

  void _showColorPicker(Function(Color) onColor) async {
    // For simplicity, use a few preset colors
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.yellow, Colors.teal, Colors.pink, Colors.grey];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pick a Color'),
        content: Wrap(
          spacing: 10,
          children: colors.map((c) => GestureDetector(
            onTap: () { onColor(c); Navigator.pop(ctx); _saveSettings(); },
            child: CircleAvatar(backgroundColor: c, radius: 18),
          )).toList(),
        ),
      ),
    );
  }

  void _showContactPicker(Function(String) onPick, {bool allowMultiple = false, List<String>? initial}) {
    List<String> selected = initial != null ? List.from(initial) : [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Select Contacts/Groups'),
        content: Container(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: contacts.map((c) => CheckboxListTile(
              value: selected.contains(c['id']),
              title: Text(c['name'] ?? ''),
              onChanged: (v) {
                setState(() {
                  if (v == true) selected.add(c['id']!);
                  else selected.remove(c['id']);
                });
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(onPressed: () {
            for (var id in selected) { onPick(id); }
            Navigator.pop(ctx);
            _saveSettings();
          }, child: Text('OK')),
        ],
      ),
    );
  }

  void _showSoundPicker(String id) async {
    // For demo, just set a fake path
    setState(() { customSounds[id] = '/storage/emulated/0/Notifications/custom_$id.mp3'; });
    _saveSettings();
  }

  void _testNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          personalMode
            ? 'New message received'
            : 'From Alice: "Test notification!"',
        ),
        backgroundColor: notifIconColor ?? Theme.of(context).primaryColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 18, left: 16, bottom: 6),
    child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[700])),
  );

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Notification Settings')),
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
        title: Text("Notification",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
      ),
      body: ListView(
        children: [
          // Main Switch
          _sectionTitle('General'),
          SwitchListTile(
            title: Text("Enable All Notifications", style: TextStyle(color: Colors.grey.shade700)),
            value: notifAll,
            onChanged: (v) { setState(() { notifAll = v; }); _saveSettings(); },
            tileColor: Colors.white,
            shape: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          // Incoming Message Notification
          _sectionTitle('Incoming Message Notification'),
          SwitchListTile(
            title: Text("Personal Chat Notifications"),
            value: notifPersonal,
            onChanged: notifAll ? (v) { setState(() { notifPersonal = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text("Group Chat Notifications"),
            value: notifGroup,
            onChanged: notifAll ? (v) { setState(() { notifGroup = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text("Show Message Preview (Personal)"),
            value: previewPersonal,
            onChanged: notifAll && notifPersonal ? (v) { setState(() { previewPersonal = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text("Show Message Preview (Group)"),
            value: previewGroup,
            onChanged: notifAll && notifGroup ? (v) { setState(() { previewGroup = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Special Vibes per Contact/Group'),
            subtitle: Text('Set custom notification for contacts/groups'),
            trailing: Icon(Icons.chevron_right),
            onTap: notifAll ? () {
              _showContactPicker((id) {
                setState(() { specialVibes[id] = !(specialVibes[id] ?? false); });
              }, allowMultiple: true, initial: specialVibes.keys.toList());
            } : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Priority Contacts'),
            subtitle: Text('Allow notifications from selected contacts'),
            trailing: Icon(Icons.chevron_right),
            onTap: notifAll ? () {
              _showContactPicker((id) {
                setState(() {
                  if (priorityContacts.contains(id)) priorityContacts.remove(id);
                  else priorityContacts.add(id);
                });
                _saveSettings();
              }, allowMultiple: true, initial: priorityContacts);
            } : null,
            tileColor: Colors.white,
          ),
          // Personal Mode
          _sectionTitle('Personal Mode'),
          SwitchListTile(
            title: Text("Hide Sender & Message Content"),
            subtitle: Text("Show generic 'new messages' notification"),
            value: personalMode,
            onChanged: notifAll ? (v) { setState(() { personalMode = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text("Auto-activate by Schedule"),
            value: personalModeAuto,
            onChanged: notifAll && personalMode ? (v) { setState(() { personalModeAuto = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          if (personalModeAuto)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: notifAll && personalModeAuto ? () => _pickTime(context, personalModeStart, (t) { setState(() { personalModeStart = t; }); _saveSettings(); }) : null,
                  child: Text('Start: ${personalModeStart != null ? personalModeStart!.format(context) : '--:--'}'),
                ),
                TextButton(
                  onPressed: notifAll && personalModeAuto ? () => _pickTime(context, personalModeEnd, (t) { setState(() { personalModeEnd = t; }); _saveSettings(); }) : null,
                  child: Text('End: ${personalModeEnd != null ? personalModeEnd!.format(context) : '--:--'}'),
                ),
              ],
            ),
          // DND
          _sectionTitle("Don't Disturb Mode (DND)"),
          SwitchListTile(
            title: Text("Enable DND"),
            value: dndMode,
            onChanged: notifAll ? (v) { setState(() { dndMode = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          if (dndMode)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: notifAll && dndMode ? () => _pickTime(context, dndStart, (t) { setState(() { dndStart = t; }); _saveSettings(); }) : null,
                  child: Text('Start: ${dndStart != null ? dndStart!.format(context) : '--:--'}'),
                ),
                TextButton(
                  onPressed: notifAll && dndMode ? () => _pickTime(context, dndEnd, (t) { setState(() { dndEnd = t; }); _saveSettings(); }) : null,
                  child: Text('End: ${dndEnd != null ? dndEnd!.format(context) : '--:--'}'),
                ),
              ],
            ),
          ListTile(
            title: Text('DND Exceptions'),
            subtitle: Text('Allow notifications from selected contacts'),
            trailing: Icon(Icons.chevron_right),
            onTap: notifAll && dndMode ? () {
              _showContactPicker((id) {
                setState(() {
                  if (dndExceptions.contains(id)) dndExceptions.remove(id);
                  else dndExceptions.add(id);
                });
                _saveSettings();
              }, allowMultiple: true, initial: dndExceptions);
            } : null,
            tileColor: Colors.white,
          ),
          // Smart Notification
          _sectionTitle('Smart Notification'),
          SwitchListTile(
            title: Text("Enable AI-based Smart Notification"),
            value: smartNotif,
            onChanged: notifAll ? (v) { setState(() { smartNotif = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Special Keywords'),
            subtitle: Text(smartKeywords.isEmpty ? 'No keywords set' : smartKeywords.join(', ')),
            trailing: Icon(Icons.add),
            onTap: notifAll && smartNotif ? _showAddKeywordDialog : null,
            tileColor: Colors.white,
          ),
          // Appearance & Customization
          _sectionTitle('Appearance & Sound'),
          ListTile(
            title: Text('Notification Icon Color'),
            subtitle: notifIconColor != null ? Container(width: 24, height: 24, decoration: BoxDecoration(color: notifIconColor, shape: BoxShape.circle)) : null,
            trailing: Icon(Icons.color_lens),
            onTap: notifAll ? () => _showColorPicker((c) { setState(() { notifIconColor = c; }); }) : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Notification LED Color'),
            subtitle: notifLedColor != null ? Container(width: 24, height: 24, decoration: BoxDecoration(color: notifLedColor, shape: BoxShape.circle)) : null,
            trailing: Icon(Icons.lightbulb),
            onTap: notifAll ? () => _showColorPicker((c) { setState(() { notifLedColor = c; }); }) : null,
            tileColor: Colors.white,
          ),
          ListTile(
            title: Text('Custom Sound per Contact/Group'),
            subtitle: Text('Set custom notification sound'),
            trailing: Icon(Icons.music_note),
            onTap: notifAll ? () {
              _showContactPicker((id) { _showSoundPicker(id); }, allowMultiple: true); 
            } : null,
            tileColor: Colors.white,
          ),
          // Fast Action
          _sectionTitle('Fast Action'),
          SwitchListTile(
            title: Text("Allow Reply from Notification Panel"),
            value: fastReply,
            onChanged: notifAll ? (v) { setState(() { fastReply = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          SwitchListTile(
            title: Text("Mark as Read / Archive from Popup"),
            value: fastMarkRead,
            onChanged: notifAll ? (v) { setState(() { fastMarkRead = v; }); _saveSettings(); } : null,
            tileColor: Colors.white,
          ),
          // Test Notification
          _sectionTitle('Test'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              icon: Icon(Icons.notifications_active),
              label: Text('Test Notification'),
              onPressed: notifAll ? _testNotification : null,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45)),
            ),
          ),
        ],
      ),
    );
  }
}
