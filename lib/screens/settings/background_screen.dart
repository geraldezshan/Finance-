import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/background_controller.dart';

/// Lets the user change the app-wide background: a built-in gradient preset,
/// or any image from their gallery (scaled to fill the phone screen).
class BackgroundScreen extends StatefulWidget {
  const BackgroundScreen({super.key});

  @override
  State<BackgroundScreen> createState() => _BackgroundScreenState();
}

class _BackgroundScreenState extends State<BackgroundScreen> {
  final _bg = BackgroundController.instance;
  bool _busy = false;

  Future<void> _pickImage() async {
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1440,
        imageQuality: 90,
      );
      if (picked == null) return;
      // Copy into the app's documents folder so it survives app restarts.
      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final dest = '${dir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(dest);
      await _bg.setImage(dest);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not set image: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _bg.id.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Background')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Presets',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              for (final p in BackgroundController.presets)
                _PresetTile(
                  option: p,
                  selected: current == p.id,
                  onTap: () async {
                    await _bg.setPreset(p.id);
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Background opacity',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ValueListenableBuilder<double>(
            valueListenable: _bg.opacity,
            builder: (context, op, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: op.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(op * 100).round()}%',
                  activeColor: AppColors.primary,
                  onChanged: (v) => _bg.setOpacity(v),
                ),
                Text(
                  'Lower opacity fades the background, letting the base color '
                  'show through (${(op * 100).round()}%).',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Your image',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (current == 'image' && _bg.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.file(File(_bg.imagePath!), fit: BoxFit.cover),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _busy ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(_busy ? 'Please wait…' : 'Choose from gallery'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: a tall (portrait) image fills an Android screen best.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });
  final BgOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = option.gradient;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 3 : 1,
                ),
                gradient: gradient == null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: gradient,
                      ),
                color: gradient == null ? AppColors.bg : null,
              ),
              child: gradient == null
                  ? const Center(
                      child: Icon(Icons.smartphone, color: AppColors.textGrey))
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(option.label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}