import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _dfTokenController = TextEditingController();
  final _lxnsTokenController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final dfToken = await StorageService.read(StorageService.kDivingFishToken);
    final lxnsToken = await StorageService.read(StorageService.kLxnsToken);

    if (mounted) {
      setState(() {
        _dfTokenController.text = dfToken ?? '';
        _lxnsTokenController.text = lxnsToken ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    await StorageService.save(
      StorageService.kDivingFishToken,
      _dfTokenController.text,
    );
    await StorageService.save(
      StorageService.kLxnsToken,
      _lxnsTokenController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置已保存')));
      Navigator.pop(context, true); // Return true to indicate changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账号绑定设置')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('水鱼查分器 (Diving-Fish)'),
                TextField(
                  controller: _dfTokenController,
                  decoration: const InputDecoration(
                    labelText: 'Import Token',
                    hintText: '请输入水鱼个人资料中的 Import Token',
                    border: OutlineInputBorder(),
                    helperText: '用于上传成绩到水鱼查分器',
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('落雪查分器 (LXNS)'),
                TextField(
                  controller: _lxnsTokenController,
                  decoration: const InputDecoration(
                    labelText: '开发者 Token',
                    hintText: '请输入落雪开发者中心的 Token',
                    border: OutlineInputBorder(),
                    helperText: '用于上传成绩到落雪查分器',
                  ),
                ),

                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('保存配置'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
