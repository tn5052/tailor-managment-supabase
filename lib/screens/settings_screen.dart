import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../widgets/responsive_layout.dart';
import '../providers/theme_provider.dart';
import '../widgets/import_export_progress_dialog.dart';
import '../services/import_export_service.dart';
import '../widgets/export_filter_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_screen.dart'; // Add this import at the top with other imports

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Settings', style: theme.textTheme.titleLarge),
            centerTitle: isMobile,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appearance', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Dark Mode'),
                        subtitle: Text(
                          'Switch between light and dark theme',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        leading: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: theme.colorScheme.primary,
                        ),
                        trailing: Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (_) => themeProvider.toggleTheme(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Data Management Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Management',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Import Data'),
                        subtitle: const Text(
                          'Import customers and measurements from Excel',
                        ),
                        leading: Icon(
                          Icons.upload_file,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: () => _handleImport(context),
                      ),
                      ListTile(
                        title: const Text('Export Data'),
                        subtitle: const Text(
                          'Export customers and measurements to Excel',
                        ),
                        leading: Icon(
                          Icons.download,
                          color: theme.colorScheme.primary,
                        ),
                        onTap: () => _handleExport(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Add this new card after the Data Management Card
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Sign Out'),
                        subtitle: const Text('Log out from your account'),
                        leading: Icon(
                          Icons.logout,
                          color: theme.colorScheme.error,
                        ),
                        onTap: () => _handleSignOut(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Add this section for Business Management before the last section
              _buildSectionTitle('Business Management'),
              _buildSettingsTile(
                context,
                icon: Icons.inventory,
                title: 'Inventory Management',
                subtitle: 'Manage fabrics, accessories and stock levels',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      FilePickerResult? result;

      if (Platform.isMacOS) {
        // Special handling for macOS
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          allowMultiple: false,
          withData: true,
          onFileLoading: (FilePickerStatus status) => print(status),
          dialogTitle: 'Please select an Excel file',
        );
      } else {
        // Handling for other platforms
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
          allowMultiple: false,
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final importExportService = ImportExportService();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => ImportExportProgressDialog(
                title: 'Importing Data',
                service: importExportService,
              ),
        );

        File? file;
        if (kIsWeb) {
          // Web handling remains the same
          // ...existing web code...
        } else {
          if (result.files.first.bytes != null) {
            // For desktop platforms
            final tempDir = await getTemporaryDirectory();
            file = File('${tempDir.path}/${result.files.first.name}');
            await file.writeAsBytes(result.files.first.bytes!);
          } else {
            // For mobile platforms
            file = File(result.files.first.path!);
          }
        }

        if (file != null) {
          await importExportService.importExcel(file);

          Navigator.pop(context); // Close progress dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully')),
          );
        }
      }
    } catch (e) {
      print('File picker error: $e'); // Add this debug print
      Navigator.pop(context); // Close progress dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error importing data: $e')));
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final filter = await showDialog<ExportFilterType>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const ExportFilterDialog(),
      );
      if (filter == null) return;

      final importExportService = ImportExportService();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => ImportExportProgressDialog(
              title: 'Exporting Data',
              service: importExportService,
            ),
      );
      final file = await importExportService.exportExcel(filter: filter);
      Navigator.pop(context); // Close progress dialog

      if (kIsWeb) {
        // Web handling...
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Excel File',
          fileName: 'exported_data.xlsx',
          allowedExtensions: ['xlsx'],
          type: FileType.custom,
        );
        if (outputFile != null) {
          await file.copy(outputFile);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File saved to: $outputFile')));
        }
      } else {
        final result = await Share.shareXFiles([
          XFile(file.path),
        ], subject: 'Exported Data');
        if (result.status != ShareResultStatus.success) {
          throw Exception('Error sharing file');
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error exporting data: $e')));
    }
  }

  // Add this new method to the class
  Future<void> _handleSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
  }

