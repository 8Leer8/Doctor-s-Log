import 'package:flutter/material.dart';
import '../../data/download/download_manager.dart';
import '../../data/local/library_filter_store.dart';
import '../../data/local/profile_store.dart';
import '../../data/local/reader_settings_store.dart';
import '../../data/local/storage_stats.dart';
import '../../models/reader_settings.dart';
import '../../theme/app_theme.dart';
import '../widgets/reader/reader_settings_sheet.dart';
import '../widgets/settings/edit_name_dialog.dart';
import '../widgets/settings/profile_header.dart';
import '../widgets/settings/settings_tile.dart';
import 'data_storage_screen.dart';
import 'download_queue_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _partsRead = 0;
  int _downloaded = 0;

  @override
  void initState() {
    super.initState();
    ProfileStore.load();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final read = await ProfileStore.totalFinishedParts();
    final downloaded = await StorageStats.downloadedPartCount();
    if (!mounted) return;
    setState(() {
      _partsRead = read;
      _downloaded = downloaded;
    });
  }

  Future<void> _editName() async {
    final result = await EditNameDialog.show(context, ProfileStore.name.value);
    if (result == null) return;
    await ProfileStore.setName(result);
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refreshStats();
  }

  String _queueSubtitle(DownloadManager m) {
    final n = m.length;
    if (n == 0) return 'Nothing queued';
    if (m.isPaused) return '$n waiting · Paused';
    return '$n remaining · one at a time';
  }

  /// Same sheet as inside the reader; every change is saved for next time.
  void _openReaderSettings() {
    ReaderSettingsSheet.show(
      context,
      ReaderSettingsStore.current,
      ReaderSettingsStore.save,
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Arknight Reader',
      applicationVersion: '1.0.0',
      applicationLegalese:
          'Unofficial fan project. Arknights and its story content belong to '
          'Hypergryph and Yostar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: ProfileStore.name,
            builder: (context, name, _) => ProfileHeader(
              name: name,
              partsRead: _partsRead,
              downloaded: _downloaded,
              onEdit: _editName,
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: LibraryFilterStore.downloadedOnly,
            builder: (context, on, _) => SettingsSwitchTile(
              icon: Icons.cloud_off_outlined,
              title: 'Downloaded only',
              subtitle: 'Filters all entries in your library',
              value: on,
              onChanged: LibraryFilterStore.setDownloadedOnly,
            ),
          ),
          const SettingsDivider(),
          ListenableBuilder(
            listenable: DownloadManager.instance,
            builder: (context, _) {
              final manager = DownloadManager.instance;
              return SettingsTile(
                icon: Icons.download_outlined,
                title: 'Download queue',
                subtitle: _queueSubtitle(manager),
                trailing: manager.length > 0
                    ? _CountBadge(count: manager.length)
                    : null,
                onTap: () => _open(const DownloadQueueScreen()),
              );
            },
          ),
          SettingsTile(
            icon: Icons.storage_outlined,
            title: 'Data and storage',
            subtitle: 'Downloads, covers, reading progress',
            onTap: () => _open(const DataStorageScreen()),
          ),
          const SettingsDivider(),
          ValueListenableBuilder<ReaderSettings>(
            valueListenable: ReaderSettingsStore.settings,
            builder: (context, s, _) => SettingsTile(
              icon: Icons.auto_stories_outlined,
              title: 'Reader',
              subtitle:
                  '${s.fontSize.round()} pt · ${s.theme.label} · ${s.lineSpacing.label}',
              onTap: _openReaderSettings,
            ),
          ),
          const SettingsDivider(),
          SettingsTile(
            icon: Icons.info_outline,
            title: 'About',
            onTap: _showAbout,
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}
