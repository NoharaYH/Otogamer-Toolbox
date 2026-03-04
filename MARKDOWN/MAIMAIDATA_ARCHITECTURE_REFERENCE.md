# MaimaiData 架构参考 (Dart 结构映射)

本参考文档将 MaimaiData (Android 原生) 的核心数据与图片链路，使用 Dart 层语言范式与 Flutter 常用业务架构进行了同构转译。通过展示其底层逻辑，为 OTOKiT 项目的内存优化与检索解耦提供对比参照。

---

## 1. 歌曲数据本地关系型存储 (Room -> Drift/sqflite 映射)

MaimaiData 的核心在于 **扁平化结构入库**。它完全摒弃了在运行期内存中进行包含深层嵌套（如 `List<Chart>`、`List<Alias>`）大对象的聚合检索，而是通过强绑主外键建立索引。

### 1.1 结构域定义 (Entity Definitions)

利用 Dart 映射其 SQLite 底层数据表形态：

```dart
// 表一：主元信息库 (仅保存不可变物理特征)
class SongDataEntity {
  final int id;               // [PrimaryKey]
  final String title;
  final String genre;
  final int bpm;
  final String version;
}

// 表二：谱面拆解库 (将嵌套集合拉平成多行记录)
class ChartEntity {
  final int id;               // [PrimaryKey, AutoGenerate]
  final int songId;           // [ForeignKey(song_data.id)]
  final String difficultyType; // 枚举词缀: BASIC, ADVANCED, EXPERT...
  final double ds;            // 单体定数
  final int notesTap;         // 拆解统计算子
  final int notesTotal;
}

// 表三：别名特征库 (应对多对多模糊匹配)
class AliasEntity {
  final int id;               // [PrimaryKey, AutoGenerate]
  final int songId;           // [ForeignKey(song_data.id)]
  final String aliasText;     // 民间词缀
}

// 视图组装流 (Join Entity ViewModel)
class SongWithChartsEntity {
  final SongDataEntity songData;
  final List<ChartEntity> charts;
  final List<AliasEntity> aliases;
}
```

### 1.2 O(1) 内存消耗的联合检索流 (Dao Pattern)

MaimaiData 中任意复杂维度组合的过滤需求（如：“筛选流派为东方，等级等于 14+，且带有别名字缀”），都是在数据库层面以字符串纯拼接的庞大 SQL 语句执行。它保证了即便拥有两万张谱面对照记录，过滤时的端侧内存开销也近乎为零。

```dart
abstract class SongWithChartsDao {
  /// 基于原生的流式广播
  /// REJECT: 加载全量内容到 `List<MaiMusic>` 后执行 `.where()` 触发 O(n) 开销。
  Stream<List<SongWithChartsEntity>> searchSongsWithCharts({
    required String keyword,          // 标题、别名或谱师的混合匹配源
    required List<String> genreList,  // 流派筛选集合
    required String? levelConstraint, // 等级过滤
    required double? dsTarget,        // 拟合定数过滤
    required bool isMatchAlias,
  }) {
    // 底座执行复杂的 SQL Join 语句并响应式输出，
    // UI 层面通过 StreamBuilder 即时映射结果
    return _db.customSelect(
      '''
      SELECT * FROM song_data
      ... (包含大量的 EXISTS() 子查询条件约束)
      '''
    ).watch().map((rows) => _assembleModel(rows));
  }
}
```

---

## 2. 静态防抖极速拉取链路 (OkDownload -> Dio Download)

它的同步机制极其“偷懒”且安全：客户端从不直接读取如 Lxns、DivingFish 这样存在严重网关限缩与宕机崩溃可能性的开放 API，而是全部挂载于作者的 CDN 云资源存储桶中。

### 2.1 同步管道模型

```dart
class MaimaiDataSyncPipeline {
  // 云端前哨站
  static const String _updateJsonUrl =
      'https://bucket-1256206908.cos.ap-shanghai.myqcloud.com/update.json';

  Future<void> performSync() async {
    final dio = Dio();

    // 1. 探路阶段：获取仅数 KB 的指纹与云指针配置文件
    final response = await dio.get(_updateJsonUrl);
    final remoteVersion = response.data['dataVersion3'];
    final staticDownloadUrl = response.data['dataUrl3'];

    // 2. 验签阶段：与本地落盘版本号对比
    final int localVersion = SpUtil.getDataVersion();
    if (localVersion >= remoteVersion) return;

    // 3. 通道阶段：使用流式写入直传物理磁盘 (规避超大内存分叉)
    final String savePath = '${(await getTemporaryDirectory()).path}/songdata.json';
    await dio.download(
      staticDownloadUrl, // 直接下载被云清洗与高压缩后的完全体 JSON
      savePath,
      onReceiveProgress: (current, total) => _updateUiProgress(current, total),
    );

    // 4. 重铸阶段：读取巨型数组 -> 碎片化转换 -> SQLite 事务批量插入
    final File jsonFile = File(savePath);
    final String parsedString = await jsonFile.readAsString();
    final List<dynamic> rawNodes = jsonDecode(parsedString);

    await db.transaction(() async {
      await db.clearAll();
      await db.batchInsertFlatten(rawNodes);
      SpUtil.setDataVersion(remoteVersion);
    });
  }
}
```

---

## 3. 去中心化封面流转 (Glide -> CachedNetworkImage)

MaimaiData 代码内没有任何实际意义上的媒体绑定，它对大文件的策略是“不请求，不储存，即走即查”。

### 3.1 零体积壳件占位设计

利用 Flutter 的 `cached_network_image`，完美平替了原生端 `Glide` 在内存自动调度（缓存置换 LRU）的能力，且完全隔绝了将大量二进制 Blob 塞入核心配置数据结构导致引发跨隔离区拷贝时引起卡顿阻塞（Frame Drop）的地雷。

```dart
import 'package:cached_network_image/cached_network_image.dart';

class KitCoverImage extends StatelessWidget {
  final int songId;
  // 直接以约定的固定外网地址作为底座基准
  static const String _imageBaseUrl = 'https://www.diving-fish.com/covers/';

  const KitCoverImage({Key? key, required this.songId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 拼装规则：主键即寻址依据
    final String absoluteImageUrl = '$_imageBaseUrl$songId.png';

    return CachedNetworkImage(
      imageUrl: absoluteImageUrl,
      // CachedNetworkImage 基于 flutter_cache_manager，
      // 会自动在本地构建最大容量的缓存管理目录，超过阈值自动淘汰。
      // 对 Flutter Engine 黑盒隐藏了 I/O 操作开销。
      placeholder: (context, url) => const KitLoadingSpinner(),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      fit: BoxFit.cover,
    );
  }
}
```

---

## 4. OTOKiT 重构落地指针 (Zero-Server Architecture)

综合评估 OTOKiT “无服务器依赖”的独立工具箱定位，结合 MaimaiData 的关系型内存降维优势，得出以下 OTOKiT 专属改良落地准则：

### 4.1 核心策略：后台端源聚合，前台流式映射

保持原生同时请求两端开放 API (Lxns & DivingFish) 不变，但是彻底阻断大数据在 Dart 主线程运行期里的持续蔓延。

- **Kernel 层基建 (SQL 底表)**
  必须依托 `drift` 构建 SQLite 底座，并储存在 `ApplicationDocumentsDirectory` 沙盒目录下。
  **建议结构**: 基于 OTOKiT 定位，应当去除 `Alias`, `Charts` 等碎表的 JOIN 损耗。把 `List<Chart>` 压缩成 JSON 字符串塞在 `mai_songs` 主数据表的一列中。
- **Logic 层异步重铸 (IO 并发)**
  将请求双源与 `MaiTransformer.transform()` 扔进 `Isolate.run` 隔离区进行防阻塞运算。结果返回后，直接 `Dao.insertAll()` 批量持久化进 SQLite，**绝不赋值回** `Provider`。
- **Application & UI 层的流式查询 (Stream Watcher)**
  `Provider` 降级为单纯的筛选条件收纳器。UI 层通过 Stream 监听 SQLite 的变化(`Dao.watchSongs(level: '14')`)，将极大地降低过滤检索引发的端侧发热与 GC。
- **图片媒体分离 (Asset Decoupling)**
  彻底断绝将媒体流以 Blob 或 Base64 打入数据库的念头，必须依靠固定路径模板组装(`$_imageBaseUrl$songId.png`)并结合本地图片缓存框架实现去中心化管理。

---

## 5. 已实施的代码改动 (Implemented Changes)

### 5.1 新增文件

- `lib/logic/mai_music_data/data_formats/mai_song_row.dart` — SQLite 持久化层的扁平化行实体
  - `MaiSongRow`: 主表实体，故事内容字段可直接映射为 SQLite 列。
  - `MaiChartRow`: 谱面紧凑单元，嵌入在 `chartsJson` 列内。
  - `encodeCharts()`: 工具函数，将 `List<MaiChartRow>` 序列化为 JSON 字符串。

### 5.2 修改的文件

- `lib/logic/mai_music_data/transform/mai_transformer.dart`
  - 输出类型变更: `List<MaiMusic>` → `List<MaiSongRow>`
  - 谱面集合直接序列化写入 `chartsJson` 字段，不再在内存构建嵌套对象图。

- `lib/logic/mai_music_data/data_sync/mai_sync_handler.dart`
  - 返回类型变更: `List<MaiMusic>?` → `List<MaiSongRow>?`
  - `MaiTransformer.transform()` 被包裹在 `Isolate.run` 内全程运行，主线程完全不感知。

- `lib/application/mai/mai_music_provider.dart` 及 `lib/kernel/state/mai_music_provider.dart`
  - 更新导入。
  - 接收新数据后的将1流为 `TODO(SQLite)` 占位符，等待 DAO 层建立后接入。

### 5.3 待完成的步骤 (TODO Roadmap)

```text
1. 将 drift 添加能 pubspec.yaml 依赖
2. 在 lib/kernel/storage/sql/ 下建立底座与 DAO
   - app_database.dart     — 引擎初始化 (ApplicationDocumentsDirectory)
   - tables/              — 表结构定义 (mai_songs_table.dart)
   - daos/                — 数据访问对象 (mai_music_dao.dart)
3. 将 Provider 内的 TODO 展开为真实的 dao.batchInsert(newSongs)
4. 将 musics getter / search 替换为基于 Stream 的 DAO 查询
5. 逐步删除已废弃的 MaiLibrary (中间过渡层)
```

---

## 6. 双端合并后的 JSON 行结构示例 (MaiSongRow 输出)

以下是一首实际导入完成后由 `MaiTransformer` 输出的完整 `MaiSongRow` 行数据示例。该结构即为最终写入 SQLite `mai_songs` 表的单一行。

```json
{
  "id": 11451,
  "title": "PANDORA PARADOX",
  "artist": "TAG underground army",
  "bpm": 180,
  "type": "DX",
  "genre": "其他游戲",
  "version_text": "maimai DX",
  "version_id": 19000,
  "charts_json": "[{\"difficulty\":0,\"label\":\"Basic\",\"level\":\"6\",\"constant\":6.0,\"designer\":\"---\",\"tap\":202,\"hold\":34,\"slide\":17,\"touch\":18,\"break\":5,\"total\":276},{\"difficulty\":1,\"label\":\"Advanced\",\"level\":\"10\",\"constant\":10.5,\"designer\":\"---\",\"tap\":356,\"hold\":72,\"slide\":28,\"touch\":36,\"break\":8,\"total\":500},{\"difficulty\":2,\"label\":\"Expert\",\"level\":\"13\",\"constant\":13.3,\"designer\":\"TAG\",\"tap\":623,\"hold\":108,\"slide\":49,\"touch\":54,\"break\":16,\"total\":850},{\"difficulty\":3,\"label\":\"Master\",\"level\":\"14\",\"constant\":14.5,\"designer\":\"TAG\",\"tap\":889,\"hold\":145,\"slide\":72,\"touch\":66,\"break\":28,\"total\":1200},{\"difficulty\":4,\"label\":\"Re:Master\",\"level\":\"15\",\"constant\":15.2,\"designer\":\"TAG\",\"tap\":1034,\"hold\":203,\"slide\":91,\"touch\":84,\"break\":38,\"total\":1450}]"
}
```

`charts_json` 展开后的完整结构：

```json
[
  {
    "difficulty": 0,
    "label": "Basic",
    "level": "6",
    "constant": 6.0,
    "designer": "---",
    "tap": 202,
    "hold": 34,
    "slide": 17,
    "touch": 18,
    "break": 5,
    "total": 276
  },
  {
    "difficulty": 1,
    "label": "Advanced",
    "level": "10",
    "constant": 10.5,
    "designer": "---",
    "tap": 356,
    "hold": 72,
    "slide": 28,
    "touch": 36,
    "break": 8,
    "total": 500
  },
  {
    "difficulty": 2,
    "label": "Expert",
    "level": "13",
    "constant": 13.3,
    "designer": "TAG",
    "tap": 623,
    "hold": 108,
    "slide": 49,
    "touch": 54,
    "break": 16,
    "total": 850
  },
  {
    "difficulty": 3,
    "label": "Master",
    "level": "14",
    "constant": 14.5,
    "designer": "TAG",
    "tap": 889,
    "hold": 145,
    "slide": 72,
    "touch": 66,
    "break": 28,
    "total": 1200
  },
  {
    "difficulty": 4,
    "label": "Re:Master",
    "level": "15",
    "constant": 15.2,
    "designer": "TAG",
    "tap": 1034,
    "hold": 203,
    "slide": 91,
    "touch": 84,
    "break": 38,
    "total": 1450
  }
]
```
