import '../../repositories/vpn_repository.dart';

/// 停止传分：关闭 VPN。
class StopImportUsecase {
  const StopImportUsecase(this._vpnRepo);
  final VpnRepository _vpnRepo;

  Future<bool> execute() => _vpnRepo.stop();
}
