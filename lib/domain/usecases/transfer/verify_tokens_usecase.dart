import '../../entities/token_bundle.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/game_type.dart';
import '../../value_objects/transfer_mode.dart';
import '../../../shared/errors/auth_exception.dart';
import '../../../shared/result/result.dart';

/// 验证并保存 Token：按模式校验 DivingFish / LXNS，成功后持久化。
class VerifyTokensUsecase {
  const VerifyTokensUsecase(this._authRepo);
  final AuthRepository _authRepo;

  Future<Result<TokenBundle, AuthException>> execute(
    TokenBundle current,
    TransferMode mode,
    GameType game,
  ) async {
    if (mode.needsDivingFish && !current.hasDivingFish) {
      return Result.failure(AuthException.missingDivingFishToken());
    }
    if (mode.needsLxns && !current.hasLxns) {
      return Result.failure(AuthException.missingLxnsToken());
    }

    TokenBundle result = current;

    if (mode.needsDivingFish) {
      final r = await _authRepo.validateDivingFishToken(current.dfToken);
      if (r.isFailure) return r;
      result = r.valueOrNull!;
    }
    if (mode.needsLxns) {
      final r = await _authRepo.validateLxnsToken(current.lxnsToken, game);
      if (r.isFailure) return r;
      result = r.valueOrNull!;
    }

    await _authRepo.saveTokenBundle(result);
    return Result.success(result);
  }
}
