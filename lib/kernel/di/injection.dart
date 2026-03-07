import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../domain/games/game_registry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/music_library_repository.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../domain/repositories/vpn_repository.dart';
import '../../domain/services/html_record_parser.dart';
import '../../domain/usecases/music_data/init_music_library_usecase.dart';
import '../../domain/usecases/music_data/sync_music_library_usecase.dart';
import '../../domain/usecases/transfer/handle_native_log_usecase.dart';
import '../../domain/usecases/transfer/refresh_lxns_token_usecase.dart';
import '../../domain/usecases/transfer/start_import_usecase.dart';
import '../../domain/usecases/transfer/stop_import_usecase.dart';
import '../../domain/usecases/transfer/verify_tokens_usecase.dart';
import '../../infrastructure/games/maimai/maimai_module.dart';
import '../../infrastructure/native/channel/vpn_channel_gateway.dart';
import '../../infrastructure/parsers/maimai_html_parser_impl.dart';
import '../../infrastructure/storage/repositories_impl/auth_repository_impl.dart';
import '../../infrastructure/storage/repositories_impl/music_library_repository_impl.dart';
import '../../infrastructure/storage/repositories_impl/transfer_repository_impl.dart';
import '../config/prod_env.dart';
import '../../shared/env/app_env.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  getIt.init();
  getIt.registerLazySingleton<VpnRepository>(() => getIt<VpnChannelGateway>());
  getIt.registerLazySingleton<AppEnv>(() => getIt<ProdEnv>());
  getIt.registerLazySingleton<AuthRepository>(
    () => getIt<AuthRepositoryImpl>(),
  );
  getIt.registerLazySingleton<TransferRepository>(
    () => getIt<TransferRepositoryImpl>(),
  );
  getIt.registerLazySingleton<MusicLibraryRepository>(
    () => getIt<MusicLibraryRepositoryImpl>(),
  );
  getIt.registerLazySingleton<HtmlRecordParser>(
    () => getIt<MaimaiHtmlParserImpl>(),
  );

  getIt.registerLazySingleton<MaimaiModule>(
    () => MaimaiModule(
      getIt<AppEnv>(),
      getIt<MusicLibraryRepository>(),
      getIt<HtmlRecordParser>(),
    ),
  );
  getIt.registerLazySingleton<GameRegistry>(
    () => GameRegistry([getIt<MaimaiModule>()]),
  );

  getIt.registerLazySingleton<VerifyTokensUsecase>(
    () => VerifyTokensUsecase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<StartImportUsecase>(
    () => StartImportUsecase(getIt<VpnRepository>(), getIt<GameRegistry>()),
  );
  getIt.registerLazySingleton<StopImportUsecase>(
    () => StopImportUsecase(getIt<VpnRepository>()),
  );
  getIt.registerLazySingleton<HandleNativeLogUsecase>(
    () => HandleNativeLogUsecase(
      getIt<HtmlRecordParser>(),
      getIt<TransferRepository>(),
      getIt<VpnRepository>(),
    ),
  );
  getIt.registerLazySingleton<RefreshLxnsTokenUsecase>(
    () => RefreshLxnsTokenUsecase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<InitMusicLibraryUsecase>(
    () => InitMusicLibraryUsecase(getIt<MusicLibraryRepository>()),
  );
  getIt.registerLazySingleton<SyncMusicLibraryUsecase>(
    () => SyncMusicLibraryUsecase(getIt<MusicLibraryRepository>()),
  );
}
