/// 原生日志处理结果：纯展示文本或上传结果文案。
/// 供 HandleNativeLogUsecase 与 Controller 使用。
sealed class HandleLogResult {
  const HandleLogResult();

  factory HandleLogResult.plain(String rawLog) = HandleLogResultPlain;
  factory HandleLogResult.upload(String message) = HandleLogResultUpload;
}

final class HandleLogResultPlain extends HandleLogResult {
  const HandleLogResultPlain(this.rawLog);
  final String rawLog;
}

final class HandleLogResultUpload extends HandleLogResult {
  const HandleLogResultUpload(this.message);
  final String message;
}
