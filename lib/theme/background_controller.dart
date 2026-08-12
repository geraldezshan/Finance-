import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_theme.dart';
import 'theme_controller.dart';

/// A selectable app-wide background option.
class BgOption {
  const BgOption(this.id, this.label, {this.gradient});
  final String id;
  final String label;
  final List<Color>? gradient;
}

/// Holds the user's chosen background and paints it behind every screen.
/// Choices persist across launches via secure storage.
class BackgroundController {
  BackgroundController._();
  static final BackgroundController instance = BackgroundController._();

  static const _storage = FlutterSecureStorage();
  static const _kId = 'bg_id';
  static const _kImagePath = 'bg_image_path';
  static const _kOpacity = 'bg_opacity';

  /// Listenable so the whole app repaints when the background changes.
  final ValueNotifier<String> id = ValueNotifier<String>('default');

  /// 0..1 — how strongly the chosen background (gradient/image) shows over the
  /// plain base color. 1 = fully visible.
  final ValueNotifier<double> opacity = ValueNotifier<double>(1.0);
  String? imagePath;

  /// Built-in presets. Gradients scale to any phone size automatically.
  static const presets = <BgOption>[
    BgOption('default', 'Default'),
    BgOption('green', 'Soft Green',
        gradient: [Color(0xFFE8F5E9), Color(0xFFB7E2BD)]),
    BgOption('mint', 'Mint',
        gradient: [Color(0xFFFFFFFF), Color(0xFFD7F0E2)]),
    BgOption('dusk', 'Forest Dusk',
        gradient: [Color(0xFF1B3A2B), Color(0xFF0C1812)]),
    BgOption('ocean', 'Ocean',
        gradient: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)]),
    BgOption('sunset', 'Sunset',
        gradient: [Color(0xFFFFF3E0), Color(0xFFFFD6A5)]),
  ];

  Future<void> load() async {
    id.value = (await _storage.read(key: _kId)) ?? 'default';
    imagePath = await _storage.read(key: _kImagePath);
    final op = await _storage.read(key: _kOpacity);
    opacity.value = op == null ? 1.0 : (double.tryParse(op) ?? 1.0);
  }

  Future<void> setOpacity(double v) async {
    opacity.value = v;
    await _storage.write(key: _kOpacity, value: v.toStringAsFixed(2));
  }

  /// The solid color painted underneath the background (shows through when
  /// opacity is reduced). Matches the normal theme background.
  Color baseColor() {
    return ThemeController.instance.isDark
        ? const Color(0xFF14201A)
        : AppColors.bg;
  }

  Future<void> setPreset(String presetId) async {
    id.value = presetId;
    await _storage.write(key: _kId, value: presetId);
  }

  /// Use a saved image file (copied into the app's documents directory).
  Future<void> setImage(String path) async {
    imagePath = path;
    await _storage.write(key: _kImagePath, value: path);
    await _storage.write(key: _kId, value: 'image');
    id.value = 'image';
  }

  /// The decoration painted behind the whole app.
  BoxDecoration decoration() {
    final isDark = ThemeController.instance.isDark;

    if (id.value == 'image' &&
        imagePath != null &&
        File(imagePath!).existsSync()) {
      return BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(imagePath!)),
          fit: BoxFit.cover,
        ),
      );
    }

    final preset = presets.firstWhere(
      (p) => p.id == id.value,
      orElse: () => presets.first,
    );
    if (preset.gradient != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: preset.gradient!,
        ),
      );
    }

    // Default: the normal theme background colors (so nothing visually
    // changes unless the user picks something else).
    return BoxDecoration(
      color: isDark ? const Color(0xFF14201A) : AppColors.bg,
    );
  }
}