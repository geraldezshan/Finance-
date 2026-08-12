import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Lets the user rate the app and leave a comment. Feedback is saved straight
/// to the Supabase 'feedback' table (no email app involved).
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _data = DataService();
  int _stars = 0;
  final _comment = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_stars == 0) return _snack('Please tap a star rating first.');
    setState(() => _sending = true);
    try {
      await _data.submitFeedback(_stars, _comment.text);
      if (!mounted) return;
      _snack('Thanks! Your feedback has been sent.');
      Navigator.pop(context);
    } catch (e) {
      _snack('Could not send feedback: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Feedback')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text('How would you rate Finance+?',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        iconSize: 38,
                        onPressed: () => setState(() => _stars = i),
                        icon: Icon(
                          i <= _stars ? Icons.star : Icons.star_border,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // "Comments" label, upper-left of the box.
                const Text('Comments',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _comment,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Tell us what you think…',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
            label: Text(_sending ? 'Sending…' : 'Send feedback'),
          ),
          const SizedBox(height: 10),
          const Text('Your feedback is sent privately to the Finance+ team.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}