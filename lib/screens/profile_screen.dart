import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_info.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/common.dart';
import 'settings/edit_info_screen.dart';
import 'settings/switch_account_screen.dart';
import 'settings/faq_screen.dart';
import 'settings/feedback_screen.dart';
import 'settings/user_guide_screen.dart';
import 'settings/terms_screen.dart';
import 'settings/background_screen.dart';
import 'settings/currency_screen.dart';
import '../theme/currency_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _data = DataService();
  late final Stream<Profile?> _profile = _data.watchProfile();
  bool _uploadingAvatar = false;

  void _go(Widget screen) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _changeAvatar() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _uploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final ext =
          picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      await _data.uploadAvatar(bytes, ext);
      // The profile stream updates the avatar automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.currentUser?.email ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        const SizedBox(height: 6),
        StreamBuilder<Profile?>(
          stream: _profile,
          builder: (context, snap) {
            final name = snap.data?.fullName ?? 'Finance+ User';
            final username = snap.data?.username;
            final avatarUrl = snap.data?.avatarUrl;
            final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
            return Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary,
                        backgroundImage:
                            hasAvatar ? NetworkImage(avatarUrl) : null,
                        child: _uploadingAvatar
                            ? const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)
                            : (hasAvatar
                                ? null
                                : const Icon(Icons.person,
                                    size: 44, color: Colors.white)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploadingAvatar ? null : _changeAvatar,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt,
                                  size: 18, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                if (username != null && username.isNotEmpty)
                  Text('@$username',
                      style: const TextStyle(color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(color: AppColors.textGrey)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Account
        _sectionLabel('Account'),
        _menuCard([
          _tile(Icons.edit_outlined, 'Edit information',
              () => _go(const EditInfoScreen())),
          _divider(),
          _tile(Icons.switch_account_outlined, 'Switch account',
              () => _go(const SwitchAccountScreen())),
        ]),

        // Preferences
        _sectionLabel('Preferences'),
        _menuCard([
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance.mode,
            builder: (context, mode, _) => SwitchListTile(
              secondary: Icon(
                  mode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: AppColors.primary),
              title: const Text('Dark mode'),
              value: mode == ThemeMode.dark,
              activeColor: AppColors.primary,
              onChanged: (v) => ThemeController.instance.setDark(v),
            ),
          ),
          _divider(),
          ValueListenableBuilder<String>(
            valueListenable: CurrencyController.instance.code,
            builder: (context, _, __) {
              final cur = CurrencyController.instance.current;
              return ListTile(
                leading: const Icon(Icons.payments_outlined,
                    color: AppColors.primary),
                title: const Text('Currency'),
                trailing: Text('${cur.symbol}  ${cur.code}',
                    style: const TextStyle(color: AppColors.textGrey)),
                onTap: () => _go(const CurrencyScreen()),
              );
            },
          ),
          _divider(),
          _tile(Icons.wallpaper_outlined, 'Background',
              () => _go(const BackgroundScreen())),
        ]),

        // Help & info
        _sectionLabel('Help & info'),
        _menuCard([
          _tile(Icons.help_outline, 'Frequently asked questions',
              () => _go(const FaqScreen())),
          _divider(),
          _tile(Icons.menu_book_outlined, 'User guide',
              () => _go(const UserGuideScreen())),
          _divider(),
          _tile(Icons.feedback_outlined, 'Give feedback',
              () => _go(const FeedbackScreen())),
          _divider(),
          _tile(Icons.description_outlined, 'Terms of use',
              () => _go(const TermsScreen())),
        ]),

        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _auth.logout(),
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Log out', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            side: const BorderSide(color: Colors.red),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Finance+  •  v${AppInfo.full}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ),
      ],
    );
  }

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: AppColors.textGrey)),
      );

  Widget _menuCard(List<Widget> children) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _tile(IconData icon, String title, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
        onTap: onTap,
      );

  Widget _divider() => const Divider(height: 1, indent: 56);
}