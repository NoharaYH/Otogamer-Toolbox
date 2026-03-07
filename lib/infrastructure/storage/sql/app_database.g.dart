// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MaiMusicTableTable extends MaiMusicTable
    with TableInfo<$MaiMusicTableTable, MaiMusicTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaiMusicTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionTextMeta = const VerificationMeta(
    'versionText',
  );
  @override
  late final GeneratedColumn<String> versionText = GeneratedColumn<String>(
    'version_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<int> versionId = GeneratedColumn<int>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chartsJsonMeta = const VerificationMeta(
    'chartsJson',
  );
  @override
  late final GeneratedColumn<String> chartsJson = GeneratedColumn<String>(
    'charts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    bpm,
    type,
    genre,
    versionText,
    versionId,
    chartsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mai_music_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaiMusicTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    } else if (isInserting) {
      context.missing(_genreMeta);
    }
    if (data.containsKey('version_text')) {
      context.handle(
        _versionTextMeta,
        versionText.isAcceptableOrUnknown(
          data['version_text']!,
          _versionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionTextMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('charts_json')) {
      context.handle(
        _chartsJsonMeta,
        chartsJson.isAcceptableOrUnknown(data['charts_json']!, _chartsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_chartsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaiMusicTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaiMusicTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      )!,
      versionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_text'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_id'],
      )!,
      chartsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}charts_json'],
      )!,
    );
  }

  @override
  $MaiMusicTableTable createAlias(String alias) {
    return $MaiMusicTableTable(attachedDatabase, alias);
  }
}

class MaiMusicTableData extends DataClass
    implements Insertable<MaiMusicTableData> {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type;
  final String genre;
  final String versionText;
  final int versionId;
  final String chartsJson;
  const MaiMusicTableData({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.genre,
    required this.versionText,
    required this.versionId,
    required this.chartsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['bpm'] = Variable<int>(bpm);
    map['type'] = Variable<String>(type);
    map['genre'] = Variable<String>(genre);
    map['version_text'] = Variable<String>(versionText);
    map['version_id'] = Variable<int>(versionId);
    map['charts_json'] = Variable<String>(chartsJson);
    return map;
  }

  MaiMusicTableCompanion toCompanion(bool nullToAbsent) {
    return MaiMusicTableCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      bpm: Value(bpm),
      type: Value(type),
      genre: Value(genre),
      versionText: Value(versionText),
      versionId: Value(versionId),
      chartsJson: Value(chartsJson),
    );
  }

  factory MaiMusicTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaiMusicTableData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      bpm: serializer.fromJson<int>(json['bpm']),
      type: serializer.fromJson<String>(json['type']),
      genre: serializer.fromJson<String>(json['genre']),
      versionText: serializer.fromJson<String>(json['versionText']),
      versionId: serializer.fromJson<int>(json['versionId']),
      chartsJson: serializer.fromJson<String>(json['chartsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'bpm': serializer.toJson<int>(bpm),
      'type': serializer.toJson<String>(type),
      'genre': serializer.toJson<String>(genre),
      'versionText': serializer.toJson<String>(versionText),
      'versionId': serializer.toJson<int>(versionId),
      'chartsJson': serializer.toJson<String>(chartsJson),
    };
  }

  MaiMusicTableData copyWith({
    int? id,
    String? title,
    String? artist,
    int? bpm,
    String? type,
    String? genre,
    String? versionText,
    int? versionId,
    String? chartsJson,
  }) => MaiMusicTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    bpm: bpm ?? this.bpm,
    type: type ?? this.type,
    genre: genre ?? this.genre,
    versionText: versionText ?? this.versionText,
    versionId: versionId ?? this.versionId,
    chartsJson: chartsJson ?? this.chartsJson,
  );
  MaiMusicTableData copyWithCompanion(MaiMusicTableCompanion data) {
    return MaiMusicTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      type: data.type.present ? data.type.value : this.type,
      genre: data.genre.present ? data.genre.value : this.genre,
      versionText: data.versionText.present
          ? data.versionText.value
          : this.versionText,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      chartsJson: data.chartsJson.present
          ? data.chartsJson.value
          : this.chartsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaiMusicTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('bpm: $bpm, ')
          ..write('type: $type, ')
          ..write('genre: $genre, ')
          ..write('versionText: $versionText, ')
          ..write('versionId: $versionId, ')
          ..write('chartsJson: $chartsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    bpm,
    type,
    genre,
    versionText,
    versionId,
    chartsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaiMusicTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.bpm == this.bpm &&
          other.type == this.type &&
          other.genre == this.genre &&
          other.versionText == this.versionText &&
          other.versionId == this.versionId &&
          other.chartsJson == this.chartsJson);
}

class MaiMusicTableCompanion extends UpdateCompanion<MaiMusicTableData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> bpm;
  final Value<String> type;
  final Value<String> genre;
  final Value<String> versionText;
  final Value<int> versionId;
  final Value<String> chartsJson;
  const MaiMusicTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.bpm = const Value.absent(),
    this.type = const Value.absent(),
    this.genre = const Value.absent(),
    this.versionText = const Value.absent(),
    this.versionId = const Value.absent(),
    this.chartsJson = const Value.absent(),
  });
  MaiMusicTableCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String artist,
    required int bpm,
    required String type,
    required String genre,
    required String versionText,
    required int versionId,
    required String chartsJson,
  }) : title = Value(title),
       artist = Value(artist),
       bpm = Value(bpm),
       type = Value(type),
       genre = Value(genre),
       versionText = Value(versionText),
       versionId = Value(versionId),
       chartsJson = Value(chartsJson);
  static Insertable<MaiMusicTableData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? bpm,
    Expression<String>? type,
    Expression<String>? genre,
    Expression<String>? versionText,
    Expression<int>? versionId,
    Expression<String>? chartsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (bpm != null) 'bpm': bpm,
      if (type != null) 'type': type,
      if (genre != null) 'genre': genre,
      if (versionText != null) 'version_text': versionText,
      if (versionId != null) 'version_id': versionId,
      if (chartsJson != null) 'charts_json': chartsJson,
    });
  }

  MaiMusicTableCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<int>? bpm,
    Value<String>? type,
    Value<String>? genre,
    Value<String>? versionText,
    Value<int>? versionId,
    Value<String>? chartsJson,
  }) {
    return MaiMusicTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      bpm: bpm ?? this.bpm,
      type: type ?? this.type,
      genre: genre ?? this.genre,
      versionText: versionText ?? this.versionText,
      versionId: versionId ?? this.versionId,
      chartsJson: chartsJson ?? this.chartsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (versionText.present) {
      map['version_text'] = Variable<String>(versionText.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<int>(versionId.value);
    }
    if (chartsJson.present) {
      map['charts_json'] = Variable<String>(chartsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaiMusicTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('bpm: $bpm, ')
          ..write('type: $type, ')
          ..write('genre: $genre, ')
          ..write('versionText: $versionText, ')
          ..write('versionId: $versionId, ')
          ..write('chartsJson: $chartsJson')
          ..write(')'))
        .toString();
  }
}

class $MaiUtageTableTable extends MaiUtageTable
    with TableInfo<$MaiUtageTableTable, MaiUtageTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaiUtageTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<int> bpm = GeneratedColumn<int>(
    'bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionTextMeta = const VerificationMeta(
    'versionText',
  );
  @override
  late final GeneratedColumn<String> versionText = GeneratedColumn<String>(
    'version_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionIdMeta = const VerificationMeta(
    'versionId',
  );
  @override
  late final GeneratedColumn<int> versionId = GeneratedColumn<int>(
    'version_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utageInfoJsonMeta = const VerificationMeta(
    'utageInfoJson',
  );
  @override
  late final GeneratedColumn<String> utageInfoJson = GeneratedColumn<String>(
    'utage_info_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _utageChartsJsonMeta = const VerificationMeta(
    'utageChartsJson',
  );
  @override
  late final GeneratedColumn<String> utageChartsJson = GeneratedColumn<String>(
    'utage_charts_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    bpm,
    type,
    versionText,
    versionId,
    utageInfoJson,
    utageChartsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mai_utage_data';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaiUtageTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    } else if (isInserting) {
      context.missing(_bpmMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('version_text')) {
      context.handle(
        _versionTextMeta,
        versionText.isAcceptableOrUnknown(
          data['version_text']!,
          _versionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionTextMeta);
    }
    if (data.containsKey('version_id')) {
      context.handle(
        _versionIdMeta,
        versionId.isAcceptableOrUnknown(data['version_id']!, _versionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_versionIdMeta);
    }
    if (data.containsKey('utage_info_json')) {
      context.handle(
        _utageInfoJsonMeta,
        utageInfoJson.isAcceptableOrUnknown(
          data['utage_info_json']!,
          _utageInfoJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utageInfoJsonMeta);
    }
    if (data.containsKey('utage_charts_json')) {
      context.handle(
        _utageChartsJsonMeta,
        utageChartsJson.isAcceptableOrUnknown(
          data['utage_charts_json']!,
          _utageChartsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utageChartsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaiUtageTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaiUtageTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bpm'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      versionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_text'],
      )!,
      versionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_id'],
      )!,
      utageInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}utage_info_json'],
      )!,
      utageChartsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}utage_charts_json'],
      )!,
    );
  }

  @override
  $MaiUtageTableTable createAlias(String alias) {
    return $MaiUtageTableTable(attachedDatabase, alias);
  }
}

class MaiUtageTableData extends DataClass
    implements Insertable<MaiUtageTableData> {
  final int id;
  final String title;
  final String artist;
  final int bpm;
  final String type;
  final String versionText;
  final int versionId;
  final String utageInfoJson;
  final String utageChartsJson;
  const MaiUtageTableData({
    required this.id,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.type,
    required this.versionText,
    required this.versionId,
    required this.utageInfoJson,
    required this.utageChartsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['bpm'] = Variable<int>(bpm);
    map['type'] = Variable<String>(type);
    map['version_text'] = Variable<String>(versionText);
    map['version_id'] = Variable<int>(versionId);
    map['utage_info_json'] = Variable<String>(utageInfoJson);
    map['utage_charts_json'] = Variable<String>(utageChartsJson);
    return map;
  }

  MaiUtageTableCompanion toCompanion(bool nullToAbsent) {
    return MaiUtageTableCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      bpm: Value(bpm),
      type: Value(type),
      versionText: Value(versionText),
      versionId: Value(versionId),
      utageInfoJson: Value(utageInfoJson),
      utageChartsJson: Value(utageChartsJson),
    );
  }

  factory MaiUtageTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaiUtageTableData(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      bpm: serializer.fromJson<int>(json['bpm']),
      type: serializer.fromJson<String>(json['type']),
      versionText: serializer.fromJson<String>(json['versionText']),
      versionId: serializer.fromJson<int>(json['versionId']),
      utageInfoJson: serializer.fromJson<String>(json['utageInfoJson']),
      utageChartsJson: serializer.fromJson<String>(json['utageChartsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'bpm': serializer.toJson<int>(bpm),
      'type': serializer.toJson<String>(type),
      'versionText': serializer.toJson<String>(versionText),
      'versionId': serializer.toJson<int>(versionId),
      'utageInfoJson': serializer.toJson<String>(utageInfoJson),
      'utageChartsJson': serializer.toJson<String>(utageChartsJson),
    };
  }

  MaiUtageTableData copyWith({
    int? id,
    String? title,
    String? artist,
    int? bpm,
    String? type,
    String? versionText,
    int? versionId,
    String? utageInfoJson,
    String? utageChartsJson,
  }) => MaiUtageTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    bpm: bpm ?? this.bpm,
    type: type ?? this.type,
    versionText: versionText ?? this.versionText,
    versionId: versionId ?? this.versionId,
    utageInfoJson: utageInfoJson ?? this.utageInfoJson,
    utageChartsJson: utageChartsJson ?? this.utageChartsJson,
  );
  MaiUtageTableData copyWithCompanion(MaiUtageTableCompanion data) {
    return MaiUtageTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      type: data.type.present ? data.type.value : this.type,
      versionText: data.versionText.present
          ? data.versionText.value
          : this.versionText,
      versionId: data.versionId.present ? data.versionId.value : this.versionId,
      utageInfoJson: data.utageInfoJson.present
          ? data.utageInfoJson.value
          : this.utageInfoJson,
      utageChartsJson: data.utageChartsJson.present
          ? data.utageChartsJson.value
          : this.utageChartsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaiUtageTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('bpm: $bpm, ')
          ..write('type: $type, ')
          ..write('versionText: $versionText, ')
          ..write('versionId: $versionId, ')
          ..write('utageInfoJson: $utageInfoJson, ')
          ..write('utageChartsJson: $utageChartsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    artist,
    bpm,
    type,
    versionText,
    versionId,
    utageInfoJson,
    utageChartsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaiUtageTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.bpm == this.bpm &&
          other.type == this.type &&
          other.versionText == this.versionText &&
          other.versionId == this.versionId &&
          other.utageInfoJson == this.utageInfoJson &&
          other.utageChartsJson == this.utageChartsJson);
}

class MaiUtageTableCompanion extends UpdateCompanion<MaiUtageTableData> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<int> bpm;
  final Value<String> type;
  final Value<String> versionText;
  final Value<int> versionId;
  final Value<String> utageInfoJson;
  final Value<String> utageChartsJson;
  const MaiUtageTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.bpm = const Value.absent(),
    this.type = const Value.absent(),
    this.versionText = const Value.absent(),
    this.versionId = const Value.absent(),
    this.utageInfoJson = const Value.absent(),
    this.utageChartsJson = const Value.absent(),
  });
  MaiUtageTableCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String artist,
    required int bpm,
    required String type,
    required String versionText,
    required int versionId,
    required String utageInfoJson,
    required String utageChartsJson,
  }) : title = Value(title),
       artist = Value(artist),
       bpm = Value(bpm),
       type = Value(type),
       versionText = Value(versionText),
       versionId = Value(versionId),
       utageInfoJson = Value(utageInfoJson),
       utageChartsJson = Value(utageChartsJson);
  static Insertable<MaiUtageTableData> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<int>? bpm,
    Expression<String>? type,
    Expression<String>? versionText,
    Expression<int>? versionId,
    Expression<String>? utageInfoJson,
    Expression<String>? utageChartsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (bpm != null) 'bpm': bpm,
      if (type != null) 'type': type,
      if (versionText != null) 'version_text': versionText,
      if (versionId != null) 'version_id': versionId,
      if (utageInfoJson != null) 'utage_info_json': utageInfoJson,
      if (utageChartsJson != null) 'utage_charts_json': utageChartsJson,
    });
  }

  MaiUtageTableCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<int>? bpm,
    Value<String>? type,
    Value<String>? versionText,
    Value<int>? versionId,
    Value<String>? utageInfoJson,
    Value<String>? utageChartsJson,
  }) {
    return MaiUtageTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      bpm: bpm ?? this.bpm,
      type: type ?? this.type,
      versionText: versionText ?? this.versionText,
      versionId: versionId ?? this.versionId,
      utageInfoJson: utageInfoJson ?? this.utageInfoJson,
      utageChartsJson: utageChartsJson ?? this.utageChartsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (bpm.present) {
      map['bpm'] = Variable<int>(bpm.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (versionText.present) {
      map['version_text'] = Variable<String>(versionText.value);
    }
    if (versionId.present) {
      map['version_id'] = Variable<int>(versionId.value);
    }
    if (utageInfoJson.present) {
      map['utage_info_json'] = Variable<String>(utageInfoJson.value);
    }
    if (utageChartsJson.present) {
      map['utage_charts_json'] = Variable<String>(utageChartsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaiUtageTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('bpm: $bpm, ')
          ..write('type: $type, ')
          ..write('versionText: $versionText, ')
          ..write('versionId: $versionId, ')
          ..write('utageInfoJson: $utageInfoJson, ')
          ..write('utageChartsJson: $utageChartsJson')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MaiMusicTableTable maiMusicTable = $MaiMusicTableTable(this);
  late final $MaiUtageTableTable maiUtageTable = $MaiUtageTableTable(this);
  late final MaiMusicDao maiMusicDao = MaiMusicDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    maiMusicTable,
    maiUtageTable,
  ];
}

typedef $$MaiMusicTableTableCreateCompanionBuilder =
    MaiMusicTableCompanion Function({
      Value<int> id,
      required String title,
      required String artist,
      required int bpm,
      required String type,
      required String genre,
      required String versionText,
      required int versionId,
      required String chartsJson,
    });
typedef $$MaiMusicTableTableUpdateCompanionBuilder =
    MaiMusicTableCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> artist,
      Value<int> bpm,
      Value<String> type,
      Value<String> genre,
      Value<String> versionText,
      Value<int> versionId,
      Value<String> chartsJson,
    });

class $$MaiMusicTableTableFilterComposer
    extends Composer<_$AppDatabase, $MaiMusicTableTable> {
  $$MaiMusicTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chartsJson => $composableBuilder(
    column: $table.chartsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaiMusicTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MaiMusicTableTable> {
  $$MaiMusicTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chartsJson => $composableBuilder(
    column: $table.chartsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaiMusicTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaiMusicTableTable> {
  $$MaiMusicTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionId =>
      $composableBuilder(column: $table.versionId, builder: (column) => column);

  GeneratedColumn<String> get chartsJson => $composableBuilder(
    column: $table.chartsJson,
    builder: (column) => column,
  );
}

class $$MaiMusicTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaiMusicTableTable,
          MaiMusicTableData,
          $$MaiMusicTableTableFilterComposer,
          $$MaiMusicTableTableOrderingComposer,
          $$MaiMusicTableTableAnnotationComposer,
          $$MaiMusicTableTableCreateCompanionBuilder,
          $$MaiMusicTableTableUpdateCompanionBuilder,
          (
            MaiMusicTableData,
            BaseReferences<
              _$AppDatabase,
              $MaiMusicTableTable,
              MaiMusicTableData
            >,
          ),
          MaiMusicTableData,
          PrefetchHooks Function()
        > {
  $$MaiMusicTableTableTableManager(_$AppDatabase db, $MaiMusicTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaiMusicTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaiMusicTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaiMusicTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> genre = const Value.absent(),
                Value<String> versionText = const Value.absent(),
                Value<int> versionId = const Value.absent(),
                Value<String> chartsJson = const Value.absent(),
              }) => MaiMusicTableCompanion(
                id: id,
                title: title,
                artist: artist,
                bpm: bpm,
                type: type,
                genre: genre,
                versionText: versionText,
                versionId: versionId,
                chartsJson: chartsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String artist,
                required int bpm,
                required String type,
                required String genre,
                required String versionText,
                required int versionId,
                required String chartsJson,
              }) => MaiMusicTableCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                bpm: bpm,
                type: type,
                genre: genre,
                versionText: versionText,
                versionId: versionId,
                chartsJson: chartsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaiMusicTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaiMusicTableTable,
      MaiMusicTableData,
      $$MaiMusicTableTableFilterComposer,
      $$MaiMusicTableTableOrderingComposer,
      $$MaiMusicTableTableAnnotationComposer,
      $$MaiMusicTableTableCreateCompanionBuilder,
      $$MaiMusicTableTableUpdateCompanionBuilder,
      (
        MaiMusicTableData,
        BaseReferences<_$AppDatabase, $MaiMusicTableTable, MaiMusicTableData>,
      ),
      MaiMusicTableData,
      PrefetchHooks Function()
    >;
typedef $$MaiUtageTableTableCreateCompanionBuilder =
    MaiUtageTableCompanion Function({
      Value<int> id,
      required String title,
      required String artist,
      required int bpm,
      required String type,
      required String versionText,
      required int versionId,
      required String utageInfoJson,
      required String utageChartsJson,
    });
typedef $$MaiUtageTableTableUpdateCompanionBuilder =
    MaiUtageTableCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> artist,
      Value<int> bpm,
      Value<String> type,
      Value<String> versionText,
      Value<int> versionId,
      Value<String> utageInfoJson,
      Value<String> utageChartsJson,
    });

class $$MaiUtageTableTableFilterComposer
    extends Composer<_$AppDatabase, $MaiUtageTableTable> {
  $$MaiUtageTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get utageInfoJson => $composableBuilder(
    column: $table.utageInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get utageChartsJson => $composableBuilder(
    column: $table.utageChartsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaiUtageTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MaiUtageTableTable> {
  $$MaiUtageTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionId => $composableBuilder(
    column: $table.versionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get utageInfoJson => $composableBuilder(
    column: $table.utageInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get utageChartsJson => $composableBuilder(
    column: $table.utageChartsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaiUtageTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaiUtageTableTable> {
  $$MaiUtageTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<int> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get versionText => $composableBuilder(
    column: $table.versionText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get versionId =>
      $composableBuilder(column: $table.versionId, builder: (column) => column);

  GeneratedColumn<String> get utageInfoJson => $composableBuilder(
    column: $table.utageInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get utageChartsJson => $composableBuilder(
    column: $table.utageChartsJson,
    builder: (column) => column,
  );
}

class $$MaiUtageTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaiUtageTableTable,
          MaiUtageTableData,
          $$MaiUtageTableTableFilterComposer,
          $$MaiUtageTableTableOrderingComposer,
          $$MaiUtageTableTableAnnotationComposer,
          $$MaiUtageTableTableCreateCompanionBuilder,
          $$MaiUtageTableTableUpdateCompanionBuilder,
          (
            MaiUtageTableData,
            BaseReferences<
              _$AppDatabase,
              $MaiUtageTableTable,
              MaiUtageTableData
            >,
          ),
          MaiUtageTableData,
          PrefetchHooks Function()
        > {
  $$MaiUtageTableTableTableManager(_$AppDatabase db, $MaiUtageTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaiUtageTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaiUtageTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaiUtageTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<int> bpm = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> versionText = const Value.absent(),
                Value<int> versionId = const Value.absent(),
                Value<String> utageInfoJson = const Value.absent(),
                Value<String> utageChartsJson = const Value.absent(),
              }) => MaiUtageTableCompanion(
                id: id,
                title: title,
                artist: artist,
                bpm: bpm,
                type: type,
                versionText: versionText,
                versionId: versionId,
                utageInfoJson: utageInfoJson,
                utageChartsJson: utageChartsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String artist,
                required int bpm,
                required String type,
                required String versionText,
                required int versionId,
                required String utageInfoJson,
                required String utageChartsJson,
              }) => MaiUtageTableCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                bpm: bpm,
                type: type,
                versionText: versionText,
                versionId: versionId,
                utageInfoJson: utageInfoJson,
                utageChartsJson: utageChartsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaiUtageTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaiUtageTableTable,
      MaiUtageTableData,
      $$MaiUtageTableTableFilterComposer,
      $$MaiUtageTableTableOrderingComposer,
      $$MaiUtageTableTableAnnotationComposer,
      $$MaiUtageTableTableCreateCompanionBuilder,
      $$MaiUtageTableTableUpdateCompanionBuilder,
      (
        MaiUtageTableData,
        BaseReferences<_$AppDatabase, $MaiUtageTableTable, MaiUtageTableData>,
      ),
      MaiUtageTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MaiMusicTableTableTableManager get maiMusicTable =>
      $$MaiMusicTableTableTableManager(_db, _db.maiMusicTable);
  $$MaiUtageTableTableTableManager get maiUtageTable =>
      $$MaiUtageTableTableTableManager(_db, _db.maiUtageTable);
}
