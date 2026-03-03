import 'core/app_theme.dart';
import 'universal_theme/star_trails.dart';
import 'domain_theme/theme_mai/circle.dart';
import 'domain_theme/theme_chu/verse.dart';

/// 自动收录引擎最终生成/暴露的主题字典
/// （目前手动维护，等二期 source_gen 完成后此文件将被生成脚本接管）
class ThemeCatalog {
  /// 全局主题列表
  static const List<AppTheme> universalThemes = [StarTrailsTheme()];

  /// 舞萌主题列表
  static const List<AppTheme> maimaiThemes = [CircleTheme()];

  /// 中二节奏主题列表
  static const List<AppTheme> chunithmThemes = [VerseTheme()];

  /// 全部可用主题的扁平字典
  static List<AppTheme> get allThemes => [
    ...universalThemes,
    ...maimaiThemes,
    ...chunithmThemes,
  ];

  /// 根据主题ID查找，未找到返回全局默认
  static AppTheme findThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.themeId == id,
      orElse: () => const StarTrailsTheme(),
    );
  }
}
