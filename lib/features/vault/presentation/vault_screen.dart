import 'package:docora/core/services/document_opener.dart';
import 'package:docora/core/services/vault_service.dart';
import 'package:docora/core/theme/app_colors.dart';
import 'package:docora/core/theme/app_motion.dart';
import 'package:docora/core/theme/app_spacing.dart';
import 'package:docora/core/theme/format_helpers.dart';
import 'package:docora/core/widgets/docora_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final VaultService _vaultService = VaultService();
  bool _isUnlocked = false;
  bool _isLoading = true;
  bool _hasPin = false;
  String _enteredPin = '';
  List<VaultFile> _vaultFiles = [];
  bool _isEncrypting = false;

  @override
  void initState() {
    super.initState();
    _checkVaultSecurity();
  }

  Future<void> _checkVaultSecurity() async {
    final hasPin = await _vaultService.hasPin();
    setState(() {
      _hasPin = hasPin;
      _isLoading = false;
    });

    // Auto-prompt biometric if available
    _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    final authenticated = await _vaultService.authenticateBiometric();
    if (authenticated && mounted) {
      _unlockVault();
    }
  }

  Future<void> _unlockVault() async {
    setState(() {
      _isUnlocked = true;
      _isLoading = true;
    });
    final files = await _vaultService.listVaultFiles();
    setState(() {
      _vaultFiles = files;
      _isLoading = false;
    });
  }

  void _onPinDigit(String digit) {
    AppMotion.subtleHaptic();
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
      });

      if (_enteredPin.length == 4) {
        _verifyOrSetPin();
      }
    }
  }

  void _onPinDelete() {
    AppMotion.subtleHaptic();
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _verifyOrSetPin() async {
    if (!_hasPin) {
      // First time: set PIN
      await _vaultService.setPin(_enteredPin);
      setState(() {
        _hasPin = true;
        _enteredPin = '';
      });
      _unlockVault();
    } else {
      // Verify existing PIN
      final valid = await _vaultService.verifyPin(_enteredPin);
      if (valid) {
        _unlockVault();
      } else {
        AppMotion.subtleHaptic();
        setState(() => _enteredPin = '');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect PIN. Please try again.'),
              backgroundColor: AppColors.error500,
            ),
          );
        }
      }
    }
  }

  Future<void> _addFileToVault() async {
    AppMotion.subtleHaptic();
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() => _isEncrypting = true);
      try {
        final path = result.files.single.path!;
        final vaulted = await _vaultService.encryptFileToVault(path);
        setState(() {
          _vaultFiles.insert(0, vaulted);
          _isEncrypting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${vaulted.originalName} secured in vault!'),
              backgroundColor: AppColors.success500,
            ),
          );
        }
      } catch (e) {
        setState(() => _isEncrypting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to encrypt file: $e')),
          );
        }
      }
    }
  }

  Future<void> _openVaultFile(VaultFile file) async {
    AppMotion.subtleHaptic();
    try {
      final decryptedPath = await _vaultService.decryptForViewing(file.encryptedPath);
      if (mounted) {
        DocumentOpener.open(context, decryptedPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decryption error: $e')),
        );
      }
    }
  }

  Future<void> _deleteVaultFile(VaultFile file) async {
    AppMotion.subtleHaptic();
    await _vaultService.deleteFromVault(file.encryptedPath);
    setState(() {
      _vaultFiles.removeWhere((f) => f.encryptedPath == file.encryptedPath);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isUnlocked) {
      return _buildLockScreen(theme, colorScheme);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.shield_check, size: 20, color: AppColors.primary500),
            SizedBox(width: 8),
            Text('Private Vault'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.lock),
            tooltip: 'Lock Vault',
            onPressed: () => setState(() {
              _isUnlocked = false;
              _enteredPin = '';
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isEncrypting ? null : _addFileToVault,
        icon: const Icon(LucideIcons.file_lock),
        label: Text(_isEncrypting ? 'Encrypting...' : 'Add Document'),
      ),
      body: _vaultFiles.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.shield_alert, size: 64, color: Colors.grey),
                  const SizedBox(height: AppSpacing.md),
                  Text('Vault is Empty', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Documents added here are encrypted with AES-256\nand hidden from normal device storage.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _vaultFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final file = _vaultFiles[index];
                final ext = p.extension(file.originalName);
                final format = DocumentFormat.fromExtension(ext);

                String sizeStr = '${file.sizeBytes} B';
                if (file.sizeBytes > 1024 * 1024) {
                  sizeStr = '${(file.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
                } else if (file.sizeBytes > 1024) {
                  sizeStr = '${(file.sizeBytes / 1024).toStringAsFixed(1)} KB';
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: format.color.withAlpha(30),
                      child: Icon(format.icon, color: format.color, size: 20),
                    ),
                    title: Text(file.originalName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('$sizeStr • Encrypted'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.lock, size: 16, color: AppColors.primary500),
                        IconButton(
                          icon: const Icon(LucideIcons.trash, size: 18, color: AppColors.error500),
                          onPressed: () => _deleteVaultFile(file),
                        ),
                      ],
                    ),
                    onTap: () => _openVaultFile(file),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLockScreen(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shield_check, size: 64, color: AppColors.primary500),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _hasPin ? 'Unlock Vault' : 'Create Vault PIN',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _hasPin ? 'Enter your 4-digit security PIN' : 'Choose a 4-digit PIN for offline vault security',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xl),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final filled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.primary500 : colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: filled ? AppColors.primary500 : colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Numeric Keypad
                SizedBox(
                  width: 260,
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ...List.generate(9, (i) => _buildKeypadButton('${i + 1}')),
                      IconButton(
                        icon: const Icon(Icons.fingerprint, size: 28, color: AppColors.primary500),
                        onPressed: _attemptBiometric,
                      ),
                      _buildKeypadButton('0'),
                      IconButton(
                        icon: const Icon(LucideIcons.delete, size: 24),
                        onPressed: _onPinDelete,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onPinDigit(digit),
      borderRadius: BorderRadius.circular(30),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
