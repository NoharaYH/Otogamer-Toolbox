import 'package:injectable/injectable.dart';

import '../../../domain/entities/token_bundle.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/value_objects/game_type.dart';
import '../secure/storage_service.dart';
import '../../../shared/errors/auth_exception.dart';
import '../../../shared/result/result.dart';
import '../../network/clients/divingfish_api_client.dart';
import '../../network/clients/lxns_api_client.dart';

@lazySingleton
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._lxns,
    this._divingFish,
    this._storage,
  );

  final LxnsApiClient _lxns;
  final DivingFishApiClient _divingFish;
  final StorageService _storage;

  @override
  Future<Result<TokenBundle, AuthException>> validateDivingFishToken(
    String token,
  ) async {
    final result = await _divingFish.validateToken(token);
    return result.fold(
      (_) async {
        final bundle = await loadTokenBundle();
        return Result.success(TokenBundle(
          dfToken: token,
          lxnsToken: bundle.lxnsToken,
          lxnsRefreshToken: bundle.lxnsRefreshToken,
        ));
      },
      (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<TokenBundle, AuthException>> validateLxnsToken(
    String token,
    GameType game,
  ) async {
    final result = await _lxns.validateToken(token, game);
    return result.fold(
      (_) async {
        final bundle = await loadTokenBundle();
        return Result.success(TokenBundle(
          dfToken: bundle.dfToken,
          lxnsToken: token,
          lxnsRefreshToken: bundle.lxnsRefreshToken,
        ));
      },
      (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<TokenBundle, AuthException>> exchangeLxnsCode(
    String code,
    String verifier, {
    String? redirectUri,
  }) async {
    final result = await _lxns.exchangeCode(code, verifier, redirectUri: redirectUri);
    return result.fold(
      (dto) async {
        final bundle = await loadTokenBundle();
        final newBundle = dto.toTokenBundle(bundle);
        await saveTokenBundle(newBundle);
        return Result.success(newBundle);
      },
      (e) => Result.failure(e),
    );
  }

  @override
  Future<Result<TokenBundle, AuthException>> refreshLxnsToken(
    String refreshToken,
  ) async {
    final result = await _lxns.refreshToken(refreshToken);
    return result.fold(
      (dto) async {
        final bundle = await loadTokenBundle();
        final newBundle = dto.toTokenBundle(bundle);
        await saveTokenBundle(newBundle);
        return Result.success(newBundle);
      },
      (e) => Result.failure(e),
    );
  }

  @override
  Future<void> saveTokenBundle(TokenBundle bundle) async {
    if (bundle.dfToken.isNotEmpty) {
      await _storage.save(StorageService.kDivingFishToken, bundle.dfToken);
    }
    if (bundle.lxnsToken.isNotEmpty) {
      await _storage.save(StorageService.kLxnsTokenPrefix, bundle.lxnsToken);
    }
    if (bundle.lxnsRefreshToken != null &&
        bundle.lxnsRefreshToken!.isNotEmpty) {
      await _storage.save(
        StorageService.kLxnsRefreshTokenPrefix,
        bundle.lxnsRefreshToken!,
      );
    }
  }

  @override
  Future<TokenBundle> loadTokenBundle() async {
    final df = await _storage.read(StorageService.kDivingFishToken);
    final lxns = await _storage.read(StorageService.kLxnsTokenPrefix);
    final refresh = await _storage.read(StorageService.kLxnsRefreshTokenPrefix);
    return TokenBundle(
      dfToken: df ?? '',
      lxnsToken: lxns ?? '',
      lxnsRefreshToken: refresh,
    );
  }
}
