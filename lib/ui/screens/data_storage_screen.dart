import 'package:flutter/material.dart';
import '../../data/local/storage_stats.dart';
import '../../theme/app_theme.dart';
import '../../utils/confirm_dialog.dart';
import '../widgets/common/app_toast.dart';
import '../widgets/common/home_top_bar.dart';
import '../widgets/settings/settings_tile.dart';

/// How much space downloads and covers use, with buttons to clean them up.
class DataStorageScreen extends StatefulWidget {
  const DataStorageScreen({super.key});

  @override
  State<DataStorageScreen> createState() => _DataStorageScreenState();
}

class _DataStorageScreenState extends State<DataStorageScreen> {
  StorageSnapshot? _snap;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final snap = await StorageStats.load();
    if (!mounted) return;
    setState(() => _snap = snap);
  }

  void _done(String message) {
    AppToast.show(
      context,
      message,
      icon: Icons.check_circle_outline,
      accent: AppColors.amber,
    );
    _reload();
  }

  Future<void> _deleteDownloads() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete all downloads?',
      message:
          'Removes every downloaded part and its images from this device and '
          'cancels anything in the download queue. You can download again '
          'anytime.',
      confirmLabel: 'DELETE',
    );
    if (!ok || !mounted) return;
    await StorageStats.deleteAllDownloads();
    if (!mounted) return;
    _done('Downloads deleted');
  }

  Future<void> _clearCovers() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear cover cache?',
      message:
          'Covers that ship with the app are not affected. Covers of newer '
          'chapters will download again when needed.',
      confirmLabel: 'CLEAR',
    );
    if (!ok || !mounted) return;
    await StorageStats.clearCoverCache();
    if (!mounted) return;
    _done('Cover cache cleared');
  }

  Future<void> _resetProgress() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Reset reading progress?',
      message:
          'Every chapter goes back to unread and saved choices and resume '
          'points are forgotten. Bookmarks and downloads are kept.',
      confirmLabel: 'RESET',
    );
    if (!ok || !mounted) return;
    await StorageStats.resetReadingProgress();
    if (!mounted) return;
    _done('Reading progress reset');
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HomeTopBar(
            child: Row(
              key: const ValueKey('data-storage-bar'),
              children: [
                IconButton(
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'DATA AND STORAGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: snap == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  )
                : _buildList(snap),
          ),
        ],
      ),
    );
  }

  Widget _buildList(StorageSnapshot snap) {
    final fmt = StorageStats.formatBytes;
    final hasDownloads = snap.downloadedParts > 0 || snap.storyImageCount > 0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'USED BY THE APP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.amber,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fmt(snap.totalBytes),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Downloads ${fmt(snap.downloadsTotalBytes)}  ·  '
                'Covers ${fmt(snap.coverBytes)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.menu_book_outlined,
          title: 'Downloaded stories',
          subtitle:
              '${snap.downloadedParts} parts · ${fmt(snap.downloadsTotalBytes)}',
          trailing: hasDownloads
              ? const SettingsActionLabel('DELETE ALL', destructive: true)
              : null,
          onTap: hasDownloads ? _deleteDownloads : null,
        ),
        SettingsTile(
          icon: Icons.image_outlined,
          title: 'Cover cache',
          subtitle: '${snap.coverCount} saved · ${fmt(snap.coverBytes)}',
          trailing: snap.coverCount > 0
              ? const SettingsActionLabel('CLEAR')
              : null,
          onTap: snap.coverCount > 0 ? _clearCovers : null,
        ),
        const SettingsDivider(),
        SettingsTile(
          icon: Icons.history,
          title: 'Reset reading progress',
          subtitle: 'Finished parts, choices and resume points',
          trailing: const SettingsActionLabel('RESET', destructive: true),
          onTap: _resetProgress,
        ),
      ],
    );
  }
}
