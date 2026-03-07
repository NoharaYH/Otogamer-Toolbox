import 'dart:convert';

import '../../entities/handle_log_result.dart';
import '../../repositories/transfer_repository.dart';
import '../../repositories/vpn_repository.dart';
import '../../services/html_record_parser.dart';
import '../../value_objects/game_type.dart';

/// 处理原生日志：识别 [HTML_DATA_SYNC] 则解析并上传，否则返回原文。
/// 舞萌上传成功后通知 VpnRepository.notifyDivingFishTaskDone。
class HandleNativeLogUsecase {
  const HandleNativeLogUsecase(
    this._parser,
    this._transferRepo,
    this._vpnRepo,
  );
  final HtmlRecordParser _parser;
  final TransferRepository _transferRepo;
  final VpnRepository _vpnRepo;

  Future<HandleLogResult> execute(String rawLog, GameType game) async {
    if (!rawLog.contains('[HTML_DATA_SYNC]')) {
      return HandleLogResult.plain(rawLog);
    }

    try {
      final rawJson = rawLog.split('[HTML_DATA_SYNC]')[1];
      final payload = jsonDecode(rawJson) as Map<String, dynamic>;
      final html = payload['html'] as String;
      final token = payload['token'] as String;

      final records = _parser.parse(html);
      if (records.isEmpty) {
        await _vpnRepo.notifyDivingFishTaskDone();
        return HandleLogResult.plain('');
      }
      if (game != GameType.maimai) {
        await _vpnRepo.notifyDivingFishTaskDone();
        return HandleLogResult.plain('');
      }

      final r = await _transferRepo.uploadMaimaiRecords(token, records);
      await _vpnRepo.notifyDivingFishTaskDone();
      return HandleLogResult.upload(r.isSuccess ? '上传成功' : '上传失败');
    } catch (_) {
      await _vpnRepo.notifyDivingFishTaskDone();
      rethrow;
    }
  }
}
