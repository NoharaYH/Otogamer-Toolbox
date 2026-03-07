// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../application/chu/chu_music_provider.dart' as _i331;
import '../../application/mai/mai_music_provider.dart' as _i1008;
import '../../application/shared/game_provider.dart' as _i822;
import '../../application/shared/navigation_provider.dart' as _i155;
import '../../application/shared/toast_provider.dart' as _i533;
import '../../application/transfer/transfer_provider.dart' as _i1034;
import '../../domain/repositories/auth_repository.dart' as _i1073;
import '../../domain/repositories/music_library_repository.dart' as _i677;
import '../../domain/repositories/transfer_repository.dart' as _i395;
import '../../domain/repositories/vpn_repository.dart' as _i1017;
import '../../domain/services/html_record_parser.dart' as _i743;
import '../../infrastructure/native/channel/vpn_channel_gateway.dart' as _i106;
import '../../infrastructure/network/clients/divingfish_api_client.dart'
    as _i586;
import '../../infrastructure/network/clients/lxns_api_client.dart' as _i937;
import '../../infrastructure/network/clients/oss_api_client.dart' as _i983;
import '../../infrastructure/parsers/maimai_html_parser_impl.dart' as _i964;
import '../../infrastructure/storage/repositories_impl/auth_repository_impl.dart'
    as _i1013;
import '../../infrastructure/storage/repositories_impl/music_library_repository_impl.dart'
    as _i543;
import '../../infrastructure/storage/repositories_impl/transfer_repository_impl.dart'
    as _i39;
import '../../infrastructure/storage/sql/app_database.dart' as _i782;
import '../../infrastructure/storage/sql/daos/mai_music_dao.dart' as _i456;
import '../../logic/mai_music_data/data_sync/mai_oss_sync_handler.dart'
    as _i790;
import '../../shared/env/app_env.dart' as _i187;
import '../config/prod_env.dart' as _i543;
import '../services/api_service.dart' as _i137;
import '../services/storage_service.dart' as _i306;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i331.ChuMusicDataProvider>(() => _i331.ChuMusicDataProvider());
    gh.factory<_i155.NavigationProvider>(() => _i155.NavigationProvider());
    gh.factory<_i790.MaiOssSyncHandler>(() => _i790.MaiOssSyncHandler());
    gh.lazySingleton<_i533.ToastProvider>(() => _i533.ToastProvider());
    gh.lazySingleton<_i106.VpnChannelGateway>(() => _i106.VpnChannelGateway());
    gh.lazySingleton<_i964.MaimaiHtmlParserImpl>(
      () => _i964.MaimaiHtmlParserImpl(),
    );
    gh.lazySingleton<_i782.AppDatabase>(() => _i782.AppDatabase());
    gh.lazySingleton<_i543.ProdEnv>(() => const _i543.ProdEnv());
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i586.DivingFishApiClient>(
      () => _i586.DivingFishApiClient(gh<_i361.Dio>(), gh<_i187.AppEnv>()),
    );
    gh.lazySingleton<_i937.LxnsApiClient>(
      () => _i937.LxnsApiClient(gh<_i361.Dio>(), gh<_i187.AppEnv>()),
    );
    gh.lazySingleton<_i983.OssApiClient>(
      () => _i983.OssApiClient(gh<_i361.Dio>(), gh<_i187.AppEnv>()),
    );
    gh.lazySingleton<_i306.StorageService>(
      () => _i306.StorageService(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i39.TransferRepositoryImpl>(
      () => _i39.TransferRepositoryImpl(gh<_i586.DivingFishApiClient>()),
    );
    gh.lazySingleton<_i137.ApiService>(() => _i137.ApiService(gh<_i361.Dio>()));
    gh.factory<_i1034.TransferProvider>(
      () => _i1034.TransferProvider(
        gh<_i1073.AuthRepository>(),
        gh<_i395.TransferRepository>(),
        gh<_i1017.VpnRepository>(),
        gh<_i187.AppEnv>(),
        gh<_i743.HtmlRecordParser>(),
      ),
    );
    gh.lazySingleton<_i456.MaiMusicDao>(
      () => _i456.MaiMusicDao(gh<_i782.AppDatabase>()),
    );
    gh.lazySingleton<_i1013.AuthRepositoryImpl>(
      () => _i1013.AuthRepositoryImpl(
        gh<_i937.LxnsApiClient>(),
        gh<_i586.DivingFishApiClient>(),
        gh<_i306.StorageService>(),
      ),
    );
    gh.factory<_i1008.MaiMusicProvider>(
      () => _i1008.MaiMusicProvider(
        gh<_i456.MaiMusicDao>(),
        gh<_i677.MusicLibraryRepository>(),
        gh<_i533.ToastProvider>(),
      ),
    );
    gh.factory<_i822.GameProvider>(
      () => _i822.GameProvider(gh<_i306.StorageService>()),
    );
    gh.lazySingleton<_i543.MusicLibraryRepositoryImpl>(
      () => _i543.MusicLibraryRepositoryImpl(
        gh<_i456.MaiMusicDao>(),
        gh<_i983.OssApiClient>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
