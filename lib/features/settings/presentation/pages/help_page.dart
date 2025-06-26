import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _supportNameController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportSubjectController =
      TextEditingController();
  final TextEditingController _supportMessageController =
      TextEditingController();
  final TextEditingController _reportDescController = TextEditingController();
  String _reportCategory = 'Performance';
  File? _reportAttachment;
  String _appVersion = '';

  // FAQ Data
  final List<_FAQCategory> _faqCategories = [
    _FAQCategory(
      title: 'Account & Privacy',
      faqs: [
        _FAQ(
            q: 'How do I create an account?',
            a: 'Tap Sign Up on the login screen and follow the instructions.'),
        _FAQ(
            q: 'How do I change my phone number?',
            a: 'Go to Settings > Account > Change Number.'),
        _FAQ(
            q: 'How do I delete my account?',
            a: 'Go to Settings > Account > Delete Account. This is permanent.'),
        _FAQ(
            q: 'How do I manage my privacy settings?',
            a: 'Go to Settings > Privacy to control who can see your info.'),
      ],
    ),
    _FAQCategory(
      title: 'Messaging & Media',
      faqs: [
        _FAQ(
            q: 'How do I send a message?',
            a: 'Open a chat, type your message, and tap the send button.'),
        _FAQ(
            q: 'What do the single and double ticks mean?',
            a: 'Single tick: sent. Double tick: delivered. Blue: read.'),
        _FAQ(
            q: 'How do I send photos or videos?',
            a: 'Tap the attachment icon in a chat and select your media.'),
        _FAQ(
            q: 'How do I make a voice or video call?',
            a: 'Open a chat and tap the call or video icon at the top.'),
        _FAQ(
            q: 'What are disappearing messages?',
            a: 'Enable in chat settings to auto-delete messages after a set time.'),
      ],
    ),
    _FAQCategory(
      title: 'Groups & Communities',
      faqs: [
        _FAQ(
            q: 'How do I create a group?',
            a: 'Go to Chats > New Group and add participants.'),
        _FAQ(
            q: 'How do I join or leave a group?',
            a: 'Join via invite link or leave from group info > Exit Group.'),
        _FAQ(
            q: 'What can group admins do?',
            a: 'Admins can add/remove members, change group info, and manage settings.'),
        _FAQ(
            q: 'How do I mute group notifications?',
            a: 'Open group > tap menu > Mute notifications.'),
      ],
    ),
    _FAQCategory(
      title: 'Technical Issues',
      faqs: [
        _FAQ(
            q: 'The app crashes or won’t open.',
            a: 'Try restarting your device or reinstalling the app.'),
        _FAQ(
            q: 'I’m not receiving notifications.',
            a: 'Check notification settings and ensure background data is enabled.'),
        _FAQ(
            q: 'I have connection problems.',
            a: 'Check your internet connection or try switching networks.'),
      ],
    ),
  ];

  // Tutorials & How-To Guides
  final List<_Tutorial> _tutorials = [
    _Tutorial(
      title: 'How to Start a Group Video Call',
      steps: [
        'Open the group chat you want to call.',
        'Tap the video call icon at the top.',
        'Select participants and tap Start.',
      ],
    ),
    _Tutorial(
      title: 'How to Create a Poll in a Group',
      steps: [
        'Open the group chat.',
        'Tap the attachment (+) icon.',
        'Select Poll, enter your question and options, then send.',
      ],
    ),
    _Tutorial(
      title: 'How to Backup Your Chat History',
      steps: [
        'Go to Settings > Chats > Chat Backup.',
        'Tap Back Up Now to save your chats to the cloud.',
      ],
    ),
  ];

  // Tips & Tricks
  final List<String> _tips = [
    'Swipe right on a message to quickly reply.',
    'Long-press the record button for hands-free voice notes.',
    'Pin important chats to the top of your chat list.',
    'Quickly mute chat notifications from the chat info screen.',
  ];

  // Legal Links
  final String _privacyPolicyUrl = 'https://yourapp.com/privacy';
  final String _termsUrl = 'https://yourapp.com/terms';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  void _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  List<_FAQCategory> get _filteredFaqCategories {
    if (_searchController.text.isEmpty) return _faqCategories;
    final query = _searchController.text.toLowerCase();
    return _faqCategories
        .map((cat) => _FAQCategory(
              title: cat.title,
              faqs: cat.faqs
                  .where((faq) =>
                      faq.q.toLowerCase().contains(query) ||
                      faq.a.toLowerCase().contains(query))
                  .toList(),
            ))
        .where((cat) => cat.faqs.isNotEmpty)
        .toList();
  }

  List<_Tutorial> get _filteredTutorials {
    if (_searchController.text.isEmpty) return _tutorials;
    final query = _searchController.text.toLowerCase();
    return _tutorials
        .where((t) =>
            t.title.toLowerCase().contains(query) ||
            t.steps.any((s) => s.toLowerCase().contains(query)))
        .toList();
  }

  List<String> get _filteredTips {
    if (_searchController.text.isEmpty) return _tips;
    final query = _searchController.text.toLowerCase();
    return _tips.where((tip) => tip.toLowerCase().contains(query)).toList();
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _reportAttachment = File(result.files.single.path!);
      });
    }
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@ourapp.com',
      query: 'subject=Support Request',
    );
    await launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search help topics... ',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 24),

          // FAQ Section
          Text('Frequently Asked Questions',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._filteredFaqCategories.map((cat) => ExpansionTile(
                title: Text(cat.title, style: theme.textTheme.titleMedium),
                children: cat.faqs
                    .map((faq) => ListTile(
                          title: Text(faq.q,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(faq.a),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 24),

          // Tutorials & How-To Guides
          Text('Tutorials & How-To Guides',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._filteredTutorials.map((tut) => ExpansionTile(
                title: Text(tut.title, style: theme.textTheme.titleMedium),
                children: tut.steps
                    .map((step) => ListTile(
                          leading:
                              const Icon(Icons.check_circle_outline, size: 20),
                          title: Text(step),
                        ))
                    .toList(),
              )),
          const SizedBox(height: 24),

          // Tips & Tricks
          Text('Tips & Tricks',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._filteredTips.map((tip) => ListTile(
                leading:
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                title: Text(tip),
              )),
          const SizedBox(height: 24),

          // Contact Support
          Text('Contact Support',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: const Text('support@ourapp.com'),
            onTap: _launchEmail,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('In-App Support Form'),
            subtitle: const Text('Submit your query directly from the app.'),
            onTap: () => _showSupportForm(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
                'Support Hours: Monday - Friday, 9 AM - 5 PM WIB\nTypical response time: within 24 hours.',
                style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 24),

          // Report an Issue
          Text('Report an Issue',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Bug or Issue'),
            subtitle:
                const Text('Describe the problem and attach screenshots.'),
            onTap: () => _showReportIssueForm(context),
          ),
          const SizedBox(height: 24),

          // App Version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: Text(_appVersion.isEmpty ? 'Loading...' : _appVersion),
          ),

          // Legal & Policy Links
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () async => await launchUrl(Uri.parse(_privacyPolicyUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Terms of Service'),
            onTap: () async => await launchUrl(Uri.parse(_termsUrl)),
          ),
        ],
      ),
    );
  }

  void _showSupportForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _supportNameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _supportEmailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _supportSubjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: _supportMessageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would send the support request to your backend
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support request submitted!')),
                );
                _supportNameController.clear();
                _supportEmailController.clear();
                _supportSubjectController.clear();
                _supportMessageController.clear();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showReportIssueForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report an Issue'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _reportCategory,
                  items: const [
                    DropdownMenuItem(
                        value: 'Performance', child: Text('Performance')),
                    DropdownMenuItem(value: 'UI Bug', child: Text('UI Bug')),
                    DropdownMenuItem(
                        value: 'Feature Malfunction',
                        child: Text('Feature Malfunction')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _reportCategory = val);
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: _reportDescController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach File'),
                    ),
                    const SizedBox(width: 8),
                    if (_reportAttachment != null)
                      Expanded(
                        child: Text(
                          _reportAttachment!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would send the report to your backend
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Issue reported!')),
                );
                _reportDescController.clear();
                setState(() => _reportAttachment = null);
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

// --- Data Models ---
class _FAQCategory {
  final String title;
  final List<_FAQ> faqs;
  const _FAQCategory({required this.title, required this.faqs});
}

class _FAQ {
  final String q;
  final String a;
  const _FAQ({required this.q, required this.a});
}

class _Tutorial {
  final String title;
  final List<String> steps;
  const _Tutorial({required this.title, required this.steps});
}
