import '../../entities/token_bundle.dart';
import '../../games/game_registry.dart';
import '../../repositories/vpn_repository.dart';
import '../../value_objects/difficulty_set.dart';
import '../../value_objects/game_type.dart';
import '../../value_objects/transfer_mode.dart';

/// 根据游戏与模式构建 VPN 配置并启动传分。
class StartImportUsecase {
  const StartImportUsecase(this._vpnRepo, this._registry);
  final VpnRepository _vpnRepo;
  final GameRegistry _registry;

  Future<void> execute({
    required GameType game,
    required TransferMode mode,
    required DifficultySet difficulties,
    required TokenBundle tokens,
  }) async {
    final module = _registry.findByType(game);
    if (module == null) return;

    final config = module.buildVpnConfig(
      tokens: tokens,
      mode: mode,
      difficulties: difficulties,
    );
    await _vpnRepo.prepareAndStart(config);
  }
}
