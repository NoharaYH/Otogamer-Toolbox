import '../../entities/token_bundle.dart';
import '../../repositories/auth_repository.dart';
import '../../../shared/errors/auth_exception.dart';
import '../../../shared/result/result.dart';

/// 静默刷新 LXNS Token：若当前 bundle 可刷新则刷新并保存，否则返回当前 bundle。
class RefreshLxnsTokenUsecase {
  const RefreshLxnsTokenUsecase(this._authRepo);
  final AuthRepository _authRepo;

  Future<Result<TokenBundle, AuthException>> execute(TokenBundle current) async {
    if (!current.canRefresh) {
      return Result.success(current);
    }
    final r = await _authRepo.refreshLxnsToken(current.lxnsRefreshToken!);
    if (r.isFailure) return r;
    final newBundle = r.valueOrNull!;
    await _authRepo.saveTokenBundle(newBundle);
    return Result.success(newBundle);
  }
}
