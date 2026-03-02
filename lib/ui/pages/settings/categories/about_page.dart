import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../design_system/constants/sizes.dart';
import '../../../design_system/constants/colors.dart';
import '../../../design_system/kit_shared/kit_staggered_entrance.dart';
import '../../../design_system/kit_shared/kit_bounce_scaler.dart';

/// 设置页: 应用信息专页 (v1.2 - URL Integration)
/// 遵循 SECONDARY_PAGE_SPEC 与 CARD_PROTOCOL。
class AboutPage extends StatefulWidget {
  final Color themeColor;

  const AboutPage({super.key, this.themeColor = Colors.grey});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = "Loading...";
  String _buildNumber = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('about_page_view'),
      clipBehavior: Clip.none,
      padding: EdgeInsets.symmetric(
        horizontal: UiSizes.getHorizontalMargin(context),
        vertical: 20,
      ),
      child: Column(
        children: [
          // 1. 应用版本
          _SettingsCard(
            index: 1,
            title: "应用版本",
            icon: Icons.info_outline,
            child: _buildInfoRow("当前版本", "v$_version (+$_buildNumber)"),
          ),
          const SizedBox(height: 12),

          // 2. 检查应用更新
          _SettingsCard(
            index: 2,
            title: "检查应用更新",
            icon: Icons.update_outlined,
            child: KitBounceScaler(
              onTap: () =>
                  _launchURL("https://github.com/NoharaYH/OTOKiT/releases"),
              child: _buildActionRow("点击检查新版本"),
            ),
          ),
          const SizedBox(height: 12),

          // 3. GitHub 仓库
          _SettingsCard(
            index: 3,
            title: "GitHub 仓库地址",
            icon: Icons.code_rounded,
            child: KitBounceScaler(
              onTap: () => _launchURL("https://github.com/NoharaYH/OTOKiT"),
              child: _buildLinkColumn(
                "NoharaYH/OTOKiT",
                "https://github.com/NoharaYH/OTOKiT",
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 4. 建议和反馈
          _SettingsCard(
            index: 4,
            title: "建议和反馈",
            icon: Icons.feedback_outlined,
            child: KitBounceScaler(
              onTap: () =>
                  _launchURL("https://github.com/NoharaYH/OTOKiT/issues"),
              child: _buildLinkColumn("提交 Issue 或功能请求", "前往 GitHub Issues 门户"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: UiColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: UiColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: UiColors.grey800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: UiColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: UiColors.grey700,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: UiColors.grey400),
        ],
      ),
    );
  }

  Widget _buildLinkColumn(String title, String subTitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: UiColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: UiColors.grey700,
                  ),
                ),
              ),
              const Icon(Icons.open_in_new, size: 16, color: UiColors.grey400),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subTitle,
            style: const TextStyle(fontSize: 12, color: UiColors.grey500),
          ),
        ],
      ),
    );
  }
}

/// 标准设置卡片包装器 (遵循 CARD_PROTOCOL)
class _SettingsCard extends StatelessWidget {
  final int index;
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsCard({
    required this.index,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KitStaggeredEntrance(
      index: index,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(UiSizes.cardContentPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(UiSizes.cardRadius),
          boxShadow: [
            BoxShadow(
              color: UiColors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: UiColors.grey700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: UiColors.grey800,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
