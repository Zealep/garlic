// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KvEntriesTable extends KvEntries
    with TableInfo<$KvEntriesTable, KvEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<DateTime> actualizado = GeneratedColumn<DateTime>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor, actualizado];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  KvEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvEntry(
      clave:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}clave'],
          )!,
      valor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}valor'],
          )!,
      actualizado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}actualizado'],
          )!,
    );
  }

  @override
  $KvEntriesTable createAlias(String alias) {
    return $KvEntriesTable(attachedDatabase, alias);
  }
}

class KvEntry extends DataClass implements Insertable<KvEntry> {
  final String clave;
  final String valor;
  final DateTime actualizado;
  const KvEntry({
    required this.clave,
    required this.valor,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    map['actualizado'] = Variable<DateTime>(actualizado);
    return map;
  }

  KvEntriesCompanion toCompanion(bool nullToAbsent) {
    return KvEntriesCompanion(
      clave: Value(clave),
      valor: Value(valor),
      actualizado: Value(actualizado),
    );
  }

  factory KvEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvEntry(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
      actualizado: serializer.fromJson<DateTime>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
      'actualizado': serializer.toJson<DateTime>(actualizado),
    };
  }

  KvEntry copyWith({String? clave, String? valor, DateTime? actualizado}) =>
      KvEntry(
        clave: clave ?? this.clave,
        valor: valor ?? this.valor,
        actualizado: actualizado ?? this.actualizado,
      );
  KvEntry copyWithCompanion(KvEntriesCompanion data) {
    return KvEntry(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
      actualizado:
          data.actualizado.present ? data.actualizado.value : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvEntry(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor, actualizado);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvEntry &&
          other.clave == this.clave &&
          other.valor == this.valor &&
          other.actualizado == this.actualizado);
}

class KvEntriesCompanion extends UpdateCompanion<KvEntry> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<DateTime> actualizado;
  final Value<int> rowid;
  const KvEntriesCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.actualizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvEntriesCompanion.insert({
    required String clave,
    required String valor,
    required DateTime actualizado,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor),
       actualizado = Value(actualizado);
  static Insertable<KvEntry> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<DateTime>? actualizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (actualizado != null) 'actualizado': actualizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvEntriesCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<DateTime>? actualizado,
    Value<int>? rowid,
  }) {
    return KvEntriesCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      actualizado: actualizado ?? this.actualizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<DateTime>(actualizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvEntriesCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('actualizado: $actualizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LotesLocalTable extends LotesLocal
    with TableInfo<$LotesLocalTable, LotesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LotesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zonaMeta = const VerificationMeta('zona');
  @override
  late final GeneratedColumn<String> zona = GeneratedColumn<String>(
    'zona',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _agricultorMeta = const VerificationMeta(
    'agricultor',
  );
  @override
  late final GeneratedColumn<String> agricultor = GeneratedColumn<String>(
    'agricultor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<DateTime> actualizado = GeneratedColumn<DateTime>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    codigo,
    zona,
    agricultor,
    estado,
    syncState,
    syncError,
    actualizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lotes_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<LotesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('zona')) {
      context.handle(
        _zonaMeta,
        zona.isAcceptableOrUnknown(data['zona']!, _zonaMeta),
      );
    } else if (isInserting) {
      context.missing(_zonaMeta);
    }
    if (data.containsKey('agricultor')) {
      context.handle(
        _agricultorMeta,
        agricultor.isAcceptableOrUnknown(data['agricultor']!, _agricultorMeta),
      );
    } else if (isInserting) {
      context.missing(_agricultorMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LotesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LotesLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      json:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}json'],
          )!,
      codigo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}codigo'],
          )!,
      zona:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}zona'],
          )!,
      agricultor:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}agricultor'],
          )!,
      estado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}estado'],
          )!,
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_state'],
          )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      actualizado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}actualizado'],
          )!,
    );
  }

  @override
  $LotesLocalTable createAlias(String alias) {
    return $LotesLocalTable(attachedDatabase, alias);
  }
}

class LotesLocalData extends DataClass implements Insertable<LotesLocalData> {
  final String id;
  final String json;
  final String codigo;
  final String zona;
  final String agricultor;
  final String estado;
  final String syncState;
  final String? syncError;
  final DateTime actualizado;
  const LotesLocalData({
    required this.id,
    required this.json,
    required this.codigo,
    required this.zona,
    required this.agricultor,
    required this.estado,
    required this.syncState,
    this.syncError,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['codigo'] = Variable<String>(codigo);
    map['zona'] = Variable<String>(zona);
    map['agricultor'] = Variable<String>(agricultor);
    map['estado'] = Variable<String>(estado);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['actualizado'] = Variable<DateTime>(actualizado);
    return map;
  }

  LotesLocalCompanion toCompanion(bool nullToAbsent) {
    return LotesLocalCompanion(
      id: Value(id),
      json: Value(json),
      codigo: Value(codigo),
      zona: Value(zona),
      agricultor: Value(agricultor),
      estado: Value(estado),
      syncState: Value(syncState),
      syncError:
          syncError == null && nullToAbsent
              ? const Value.absent()
              : Value(syncError),
      actualizado: Value(actualizado),
    );
  }

  factory LotesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LotesLocalData(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      codigo: serializer.fromJson<String>(json['codigo']),
      zona: serializer.fromJson<String>(json['zona']),
      agricultor: serializer.fromJson<String>(json['agricultor']),
      estado: serializer.fromJson<String>(json['estado']),
      syncState: serializer.fromJson<String>(json['syncState']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      actualizado: serializer.fromJson<DateTime>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'codigo': serializer.toJson<String>(codigo),
      'zona': serializer.toJson<String>(zona),
      'agricultor': serializer.toJson<String>(agricultor),
      'estado': serializer.toJson<String>(estado),
      'syncState': serializer.toJson<String>(syncState),
      'syncError': serializer.toJson<String?>(syncError),
      'actualizado': serializer.toJson<DateTime>(actualizado),
    };
  }

  LotesLocalData copyWith({
    String? id,
    String? json,
    String? codigo,
    String? zona,
    String? agricultor,
    String? estado,
    String? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? actualizado,
  }) => LotesLocalData(
    id: id ?? this.id,
    json: json ?? this.json,
    codigo: codigo ?? this.codigo,
    zona: zona ?? this.zona,
    agricultor: agricultor ?? this.agricultor,
    estado: estado ?? this.estado,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    actualizado: actualizado ?? this.actualizado,
  );
  LotesLocalData copyWithCompanion(LotesLocalCompanion data) {
    return LotesLocalData(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      zona: data.zona.present ? data.zona.value : this.zona,
      agricultor:
          data.agricultor.present ? data.agricultor.value : this.agricultor,
      estado: data.estado.present ? data.estado.value : this.estado,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      actualizado:
          data.actualizado.present ? data.actualizado.value : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LotesLocalData(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('codigo: $codigo, ')
          ..write('zona: $zona, ')
          ..write('agricultor: $agricultor, ')
          ..write('estado: $estado, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    json,
    codigo,
    zona,
    agricultor,
    estado,
    syncState,
    syncError,
    actualizado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LotesLocalData &&
          other.id == this.id &&
          other.json == this.json &&
          other.codigo == this.codigo &&
          other.zona == this.zona &&
          other.agricultor == this.agricultor &&
          other.estado == this.estado &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.actualizado == this.actualizado);
}

class LotesLocalCompanion extends UpdateCompanion<LotesLocalData> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> codigo;
  final Value<String> zona;
  final Value<String> agricultor;
  final Value<String> estado;
  final Value<String> syncState;
  final Value<String?> syncError;
  final Value<DateTime> actualizado;
  final Value<int> rowid;
  const LotesLocalCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.codigo = const Value.absent(),
    this.zona = const Value.absent(),
    this.agricultor = const Value.absent(),
    this.estado = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.actualizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LotesLocalCompanion.insert({
    required String id,
    required String json,
    required String codigo,
    required String zona,
    required String agricultor,
    required String estado,
    required String syncState,
    this.syncError = const Value.absent(),
    required DateTime actualizado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       codigo = Value(codigo),
       zona = Value(zona),
       agricultor = Value(agricultor),
       estado = Value(estado),
       syncState = Value(syncState),
       actualizado = Value(actualizado);
  static Insertable<LotesLocalData> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? codigo,
    Expression<String>? zona,
    Expression<String>? agricultor,
    Expression<String>? estado,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? actualizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (codigo != null) 'codigo': codigo,
      if (zona != null) 'zona': zona,
      if (agricultor != null) 'agricultor': agricultor,
      if (estado != null) 'estado': estado,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (actualizado != null) 'actualizado': actualizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LotesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? codigo,
    Value<String>? zona,
    Value<String>? agricultor,
    Value<String>? estado,
    Value<String>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? actualizado,
    Value<int>? rowid,
  }) {
    return LotesLocalCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      codigo: codigo ?? this.codigo,
      zona: zona ?? this.zona,
      agricultor: agricultor ?? this.agricultor,
      estado: estado ?? this.estado,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      actualizado: actualizado ?? this.actualizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (zona.present) {
      map['zona'] = Variable<String>(zona.value);
    }
    if (agricultor.present) {
      map['agricultor'] = Variable<String>(agricultor.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<DateTime>(actualizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LotesLocalCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('codigo: $codigo, ')
          ..write('zona: $zona, ')
          ..write('agricultor: $agricultor, ')
          ..write('estado: $estado, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvaluacionesLocalTable extends EvaluacionesLocal
    with TableInfo<$EvaluacionesLocalTable, EvaluacionesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvaluacionesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loteIdMeta = const VerificationMeta('loteId');
  @override
  late final GeneratedColumn<String> loteId = GeneratedColumn<String>(
    'lote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resumenJsonMeta = const VerificationMeta(
    'resumenJson',
  );
  @override
  late final GeneratedColumn<String> resumenJson = GeneratedColumn<String>(
    'resumen_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _borradorJsonMeta = const VerificationMeta(
    'borradorJson',
  );
  @override
  late final GeneratedColumn<String> borradorJson = GeneratedColumn<String>(
    'borrador_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<DateTime> actualizado = GeneratedColumn<DateTime>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loteId,
    resumenJson,
    borradorJson,
    estado,
    fecha,
    syncState,
    syncError,
    actualizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evaluaciones_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvaluacionesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lote_id')) {
      context.handle(
        _loteIdMeta,
        loteId.isAcceptableOrUnknown(data['lote_id']!, _loteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loteIdMeta);
    }
    if (data.containsKey('resumen_json')) {
      context.handle(
        _resumenJsonMeta,
        resumenJson.isAcceptableOrUnknown(
          data['resumen_json']!,
          _resumenJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resumenJsonMeta);
    }
    if (data.containsKey('borrador_json')) {
      context.handle(
        _borradorJsonMeta,
        borradorJson.isAcceptableOrUnknown(
          data['borrador_json']!,
          _borradorJsonMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvaluacionesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvaluacionesLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      loteId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}lote_id'],
          )!,
      resumenJson:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}resumen_json'],
          )!,
      borradorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrador_json'],
      ),
      estado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}estado'],
          )!,
      fecha:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}fecha'],
          )!,
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_state'],
          )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      actualizado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}actualizado'],
          )!,
    );
  }

  @override
  $EvaluacionesLocalTable createAlias(String alias) {
    return $EvaluacionesLocalTable(attachedDatabase, alias);
  }
}

class EvaluacionesLocalData extends DataClass
    implements Insertable<EvaluacionesLocalData> {
  final String id;
  final String loteId;
  final String resumenJson;
  final String? borradorJson;
  final String estado;
  final DateTime fecha;
  final String syncState;
  final String? syncError;
  final DateTime actualizado;
  const EvaluacionesLocalData({
    required this.id,
    required this.loteId,
    required this.resumenJson,
    this.borradorJson,
    required this.estado,
    required this.fecha,
    required this.syncState,
    this.syncError,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lote_id'] = Variable<String>(loteId);
    map['resumen_json'] = Variable<String>(resumenJson);
    if (!nullToAbsent || borradorJson != null) {
      map['borrador_json'] = Variable<String>(borradorJson);
    }
    map['estado'] = Variable<String>(estado);
    map['fecha'] = Variable<DateTime>(fecha);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['actualizado'] = Variable<DateTime>(actualizado);
    return map;
  }

  EvaluacionesLocalCompanion toCompanion(bool nullToAbsent) {
    return EvaluacionesLocalCompanion(
      id: Value(id),
      loteId: Value(loteId),
      resumenJson: Value(resumenJson),
      borradorJson:
          borradorJson == null && nullToAbsent
              ? const Value.absent()
              : Value(borradorJson),
      estado: Value(estado),
      fecha: Value(fecha),
      syncState: Value(syncState),
      syncError:
          syncError == null && nullToAbsent
              ? const Value.absent()
              : Value(syncError),
      actualizado: Value(actualizado),
    );
  }

  factory EvaluacionesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvaluacionesLocalData(
      id: serializer.fromJson<String>(json['id']),
      loteId: serializer.fromJson<String>(json['loteId']),
      resumenJson: serializer.fromJson<String>(json['resumenJson']),
      borradorJson: serializer.fromJson<String?>(json['borradorJson']),
      estado: serializer.fromJson<String>(json['estado']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      syncState: serializer.fromJson<String>(json['syncState']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      actualizado: serializer.fromJson<DateTime>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loteId': serializer.toJson<String>(loteId),
      'resumenJson': serializer.toJson<String>(resumenJson),
      'borradorJson': serializer.toJson<String?>(borradorJson),
      'estado': serializer.toJson<String>(estado),
      'fecha': serializer.toJson<DateTime>(fecha),
      'syncState': serializer.toJson<String>(syncState),
      'syncError': serializer.toJson<String?>(syncError),
      'actualizado': serializer.toJson<DateTime>(actualizado),
    };
  }

  EvaluacionesLocalData copyWith({
    String? id,
    String? loteId,
    String? resumenJson,
    Value<String?> borradorJson = const Value.absent(),
    String? estado,
    DateTime? fecha,
    String? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? actualizado,
  }) => EvaluacionesLocalData(
    id: id ?? this.id,
    loteId: loteId ?? this.loteId,
    resumenJson: resumenJson ?? this.resumenJson,
    borradorJson: borradorJson.present ? borradorJson.value : this.borradorJson,
    estado: estado ?? this.estado,
    fecha: fecha ?? this.fecha,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    actualizado: actualizado ?? this.actualizado,
  );
  EvaluacionesLocalData copyWithCompanion(EvaluacionesLocalCompanion data) {
    return EvaluacionesLocalData(
      id: data.id.present ? data.id.value : this.id,
      loteId: data.loteId.present ? data.loteId.value : this.loteId,
      resumenJson:
          data.resumenJson.present ? data.resumenJson.value : this.resumenJson,
      borradorJson:
          data.borradorJson.present
              ? data.borradorJson.value
              : this.borradorJson,
      estado: data.estado.present ? data.estado.value : this.estado,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      actualizado:
          data.actualizado.present ? data.actualizado.value : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvaluacionesLocalData(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('resumenJson: $resumenJson, ')
          ..write('borradorJson: $borradorJson, ')
          ..write('estado: $estado, ')
          ..write('fecha: $fecha, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loteId,
    resumenJson,
    borradorJson,
    estado,
    fecha,
    syncState,
    syncError,
    actualizado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvaluacionesLocalData &&
          other.id == this.id &&
          other.loteId == this.loteId &&
          other.resumenJson == this.resumenJson &&
          other.borradorJson == this.borradorJson &&
          other.estado == this.estado &&
          other.fecha == this.fecha &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.actualizado == this.actualizado);
}

class EvaluacionesLocalCompanion
    extends UpdateCompanion<EvaluacionesLocalData> {
  final Value<String> id;
  final Value<String> loteId;
  final Value<String> resumenJson;
  final Value<String?> borradorJson;
  final Value<String> estado;
  final Value<DateTime> fecha;
  final Value<String> syncState;
  final Value<String?> syncError;
  final Value<DateTime> actualizado;
  final Value<int> rowid;
  const EvaluacionesLocalCompanion({
    this.id = const Value.absent(),
    this.loteId = const Value.absent(),
    this.resumenJson = const Value.absent(),
    this.borradorJson = const Value.absent(),
    this.estado = const Value.absent(),
    this.fecha = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.actualizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvaluacionesLocalCompanion.insert({
    required String id,
    required String loteId,
    required String resumenJson,
    this.borradorJson = const Value.absent(),
    required String estado,
    required DateTime fecha,
    required String syncState,
    this.syncError = const Value.absent(),
    required DateTime actualizado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loteId = Value(loteId),
       resumenJson = Value(resumenJson),
       estado = Value(estado),
       fecha = Value(fecha),
       syncState = Value(syncState),
       actualizado = Value(actualizado);
  static Insertable<EvaluacionesLocalData> custom({
    Expression<String>? id,
    Expression<String>? loteId,
    Expression<String>? resumenJson,
    Expression<String>? borradorJson,
    Expression<String>? estado,
    Expression<DateTime>? fecha,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? actualizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loteId != null) 'lote_id': loteId,
      if (resumenJson != null) 'resumen_json': resumenJson,
      if (borradorJson != null) 'borrador_json': borradorJson,
      if (estado != null) 'estado': estado,
      if (fecha != null) 'fecha': fecha,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (actualizado != null) 'actualizado': actualizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvaluacionesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? loteId,
    Value<String>? resumenJson,
    Value<String?>? borradorJson,
    Value<String>? estado,
    Value<DateTime>? fecha,
    Value<String>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? actualizado,
    Value<int>? rowid,
  }) {
    return EvaluacionesLocalCompanion(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      resumenJson: resumenJson ?? this.resumenJson,
      borradorJson: borradorJson ?? this.borradorJson,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      actualizado: actualizado ?? this.actualizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loteId.present) {
      map['lote_id'] = Variable<String>(loteId.value);
    }
    if (resumenJson.present) {
      map['resumen_json'] = Variable<String>(resumenJson.value);
    }
    if (borradorJson.present) {
      map['borrador_json'] = Variable<String>(borradorJson.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<DateTime>(actualizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvaluacionesLocalCompanion(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('resumenJson: $resumenJson, ')
          ..write('borradorJson: $borradorJson, ')
          ..write('estado: $estado, ')
          ..write('fecha: $fecha, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EvidenciasLocalTable extends EvidenciasLocal
    with TableInfo<$EvidenciasLocalTable, EvidenciasLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EvidenciasLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evaluacionIdMeta = const VerificationMeta(
    'evaluacionId',
  );
  @override
  late final GeneratedColumn<String> evaluacionId = GeneratedColumn<String>(
    'evaluacion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _muestraNumeroMeta = const VerificationMeta(
    'muestraNumero',
  );
  @override
  late final GeneratedColumn<int> muestraNumero = GeneratedColumn<int>(
    'muestra_numero',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<String> factor = GeneratedColumn<String>(
    'factor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoMeta = const VerificationMeta('creado');
  @override
  late final GeneratedColumn<DateTime> creado = GeneratedColumn<DateTime>(
    'creado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    evaluacionId,
    muestraNumero,
    factor,
    bytes,
    mime,
    syncState,
    creado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'evidencias_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<EvidenciasLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('evaluacion_id')) {
      context.handle(
        _evaluacionIdMeta,
        evaluacionId.isAcceptableOrUnknown(
          data['evaluacion_id']!,
          _evaluacionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evaluacionIdMeta);
    }
    if (data.containsKey('muestra_numero')) {
      context.handle(
        _muestraNumeroMeta,
        muestraNumero.isAcceptableOrUnknown(
          data['muestra_numero']!,
          _muestraNumeroMeta,
        ),
      );
    }
    if (data.containsKey('factor')) {
      context.handle(
        _factorMeta,
        factor.isAcceptableOrUnknown(data['factor']!, _factorMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('creado')) {
      context.handle(
        _creadoMeta,
        creado.isAcceptableOrUnknown(data['creado']!, _creadoMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EvidenciasLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EvidenciasLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      evaluacionId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}evaluacion_id'],
          )!,
      muestraNumero: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muestra_numero'],
      ),
      factor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}factor'],
      ),
      bytes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}bytes'],
          )!,
      mime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mime'],
          )!,
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_state'],
          )!,
      creado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}creado'],
          )!,
    );
  }

  @override
  $EvidenciasLocalTable createAlias(String alias) {
    return $EvidenciasLocalTable(attachedDatabase, alias);
  }
}

class EvidenciasLocalData extends DataClass
    implements Insertable<EvidenciasLocalData> {
  final String id;
  final String evaluacionId;
  final int? muestraNumero;
  final String? factor;
  final Uint8List bytes;
  final String mime;
  final String syncState;
  final DateTime creado;
  const EvidenciasLocalData({
    required this.id,
    required this.evaluacionId,
    this.muestraNumero,
    this.factor,
    required this.bytes,
    required this.mime,
    required this.syncState,
    required this.creado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['evaluacion_id'] = Variable<String>(evaluacionId);
    if (!nullToAbsent || muestraNumero != null) {
      map['muestra_numero'] = Variable<int>(muestraNumero);
    }
    if (!nullToAbsent || factor != null) {
      map['factor'] = Variable<String>(factor);
    }
    map['bytes'] = Variable<Uint8List>(bytes);
    map['mime'] = Variable<String>(mime);
    map['sync_state'] = Variable<String>(syncState);
    map['creado'] = Variable<DateTime>(creado);
    return map;
  }

  EvidenciasLocalCompanion toCompanion(bool nullToAbsent) {
    return EvidenciasLocalCompanion(
      id: Value(id),
      evaluacionId: Value(evaluacionId),
      muestraNumero:
          muestraNumero == null && nullToAbsent
              ? const Value.absent()
              : Value(muestraNumero),
      factor:
          factor == null && nullToAbsent ? const Value.absent() : Value(factor),
      bytes: Value(bytes),
      mime: Value(mime),
      syncState: Value(syncState),
      creado: Value(creado),
    );
  }

  factory EvidenciasLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EvidenciasLocalData(
      id: serializer.fromJson<String>(json['id']),
      evaluacionId: serializer.fromJson<String>(json['evaluacionId']),
      muestraNumero: serializer.fromJson<int?>(json['muestraNumero']),
      factor: serializer.fromJson<String?>(json['factor']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      mime: serializer.fromJson<String>(json['mime']),
      syncState: serializer.fromJson<String>(json['syncState']),
      creado: serializer.fromJson<DateTime>(json['creado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'evaluacionId': serializer.toJson<String>(evaluacionId),
      'muestraNumero': serializer.toJson<int?>(muestraNumero),
      'factor': serializer.toJson<String?>(factor),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'mime': serializer.toJson<String>(mime),
      'syncState': serializer.toJson<String>(syncState),
      'creado': serializer.toJson<DateTime>(creado),
    };
  }

  EvidenciasLocalData copyWith({
    String? id,
    String? evaluacionId,
    Value<int?> muestraNumero = const Value.absent(),
    Value<String?> factor = const Value.absent(),
    Uint8List? bytes,
    String? mime,
    String? syncState,
    DateTime? creado,
  }) => EvidenciasLocalData(
    id: id ?? this.id,
    evaluacionId: evaluacionId ?? this.evaluacionId,
    muestraNumero:
        muestraNumero.present ? muestraNumero.value : this.muestraNumero,
    factor: factor.present ? factor.value : this.factor,
    bytes: bytes ?? this.bytes,
    mime: mime ?? this.mime,
    syncState: syncState ?? this.syncState,
    creado: creado ?? this.creado,
  );
  EvidenciasLocalData copyWithCompanion(EvidenciasLocalCompanion data) {
    return EvidenciasLocalData(
      id: data.id.present ? data.id.value : this.id,
      evaluacionId:
          data.evaluacionId.present
              ? data.evaluacionId.value
              : this.evaluacionId,
      muestraNumero:
          data.muestraNumero.present
              ? data.muestraNumero.value
              : this.muestraNumero,
      factor: data.factor.present ? data.factor.value : this.factor,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      mime: data.mime.present ? data.mime.value : this.mime,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      creado: data.creado.present ? data.creado.value : this.creado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EvidenciasLocalData(')
          ..write('id: $id, ')
          ..write('evaluacionId: $evaluacionId, ')
          ..write('muestraNumero: $muestraNumero, ')
          ..write('factor: $factor, ')
          ..write('bytes: $bytes, ')
          ..write('mime: $mime, ')
          ..write('syncState: $syncState, ')
          ..write('creado: $creado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    evaluacionId,
    muestraNumero,
    factor,
    $driftBlobEquality.hash(bytes),
    mime,
    syncState,
    creado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EvidenciasLocalData &&
          other.id == this.id &&
          other.evaluacionId == this.evaluacionId &&
          other.muestraNumero == this.muestraNumero &&
          other.factor == this.factor &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.mime == this.mime &&
          other.syncState == this.syncState &&
          other.creado == this.creado);
}

class EvidenciasLocalCompanion extends UpdateCompanion<EvidenciasLocalData> {
  final Value<String> id;
  final Value<String> evaluacionId;
  final Value<int?> muestraNumero;
  final Value<String?> factor;
  final Value<Uint8List> bytes;
  final Value<String> mime;
  final Value<String> syncState;
  final Value<DateTime> creado;
  final Value<int> rowid;
  const EvidenciasLocalCompanion({
    this.id = const Value.absent(),
    this.evaluacionId = const Value.absent(),
    this.muestraNumero = const Value.absent(),
    this.factor = const Value.absent(),
    this.bytes = const Value.absent(),
    this.mime = const Value.absent(),
    this.syncState = const Value.absent(),
    this.creado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EvidenciasLocalCompanion.insert({
    required String id,
    required String evaluacionId,
    this.muestraNumero = const Value.absent(),
    this.factor = const Value.absent(),
    required Uint8List bytes,
    required String mime,
    required String syncState,
    required DateTime creado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       evaluacionId = Value(evaluacionId),
       bytes = Value(bytes),
       mime = Value(mime),
       syncState = Value(syncState),
       creado = Value(creado);
  static Insertable<EvidenciasLocalData> custom({
    Expression<String>? id,
    Expression<String>? evaluacionId,
    Expression<int>? muestraNumero,
    Expression<String>? factor,
    Expression<Uint8List>? bytes,
    Expression<String>? mime,
    Expression<String>? syncState,
    Expression<DateTime>? creado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (evaluacionId != null) 'evaluacion_id': evaluacionId,
      if (muestraNumero != null) 'muestra_numero': muestraNumero,
      if (factor != null) 'factor': factor,
      if (bytes != null) 'bytes': bytes,
      if (mime != null) 'mime': mime,
      if (syncState != null) 'sync_state': syncState,
      if (creado != null) 'creado': creado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EvidenciasLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? evaluacionId,
    Value<int?>? muestraNumero,
    Value<String?>? factor,
    Value<Uint8List>? bytes,
    Value<String>? mime,
    Value<String>? syncState,
    Value<DateTime>? creado,
    Value<int>? rowid,
  }) {
    return EvidenciasLocalCompanion(
      id: id ?? this.id,
      evaluacionId: evaluacionId ?? this.evaluacionId,
      muestraNumero: muestraNumero ?? this.muestraNumero,
      factor: factor ?? this.factor,
      bytes: bytes ?? this.bytes,
      mime: mime ?? this.mime,
      syncState: syncState ?? this.syncState,
      creado: creado ?? this.creado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (evaluacionId.present) {
      map['evaluacion_id'] = Variable<String>(evaluacionId.value);
    }
    if (muestraNumero.present) {
      map['muestra_numero'] = Variable<int>(muestraNumero.value);
    }
    if (factor.present) {
      map['factor'] = Variable<String>(factor.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (creado.present) {
      map['creado'] = Variable<DateTime>(creado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EvidenciasLocalCompanion(')
          ..write('id: $id, ')
          ..write('evaluacionId: $evaluacionId, ')
          ..write('muestraNumero: $muestraNumero, ')
          ..write('factor: $factor, ')
          ..write('bytes: $bytes, ')
          ..write('mime: $mime, ')
          ..write('syncState: $syncState, ')
          ..write('creado: $creado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosCompraLocalTable extends MovimientosCompraLocal
    with TableInfo<$MovimientosCompraLocalTable, MovimientosCompraLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosCompraLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loteIdMeta = const VerificationMeta('loteId');
  @override
  late final GeneratedColumn<String> loteId = GeneratedColumn<String>(
    'lote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncErrorMeta = const VerificationMeta(
    'syncError',
  );
  @override
  late final GeneratedColumn<String> syncError = GeneratedColumn<String>(
    'sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualizadoMeta = const VerificationMeta(
    'actualizado',
  );
  @override
  late final GeneratedColumn<DateTime> actualizado = GeneratedColumn<DateTime>(
    'actualizado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loteId,
    tipo,
    json,
    syncState,
    syncError,
    actualizado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos_compra_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovimientosCompraLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lote_id')) {
      context.handle(
        _loteIdMeta,
        loteId.isAcceptableOrUnknown(data['lote_id']!, _loteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loteIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('sync_error')) {
      context.handle(
        _syncErrorMeta,
        syncError.isAcceptableOrUnknown(data['sync_error']!, _syncErrorMeta),
      );
    }
    if (data.containsKey('actualizado')) {
      context.handle(
        _actualizadoMeta,
        actualizado.isAcceptableOrUnknown(
          data['actualizado']!,
          _actualizadoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_actualizadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MovimientosCompraLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovimientosCompraLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      loteId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}lote_id'],
          )!,
      tipo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tipo'],
          )!,
      json:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}json'],
          )!,
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_state'],
          )!,
      syncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_error'],
      ),
      actualizado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}actualizado'],
          )!,
    );
  }

  @override
  $MovimientosCompraLocalTable createAlias(String alias) {
    return $MovimientosCompraLocalTable(attachedDatabase, alias);
  }
}

class MovimientosCompraLocalData extends DataClass
    implements Insertable<MovimientosCompraLocalData> {
  final String id;
  final String loteId;
  final String tipo;
  final String json;
  final String syncState;
  final String? syncError;
  final DateTime actualizado;
  const MovimientosCompraLocalData({
    required this.id,
    required this.loteId,
    required this.tipo,
    required this.json,
    required this.syncState,
    this.syncError,
    required this.actualizado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lote_id'] = Variable<String>(loteId);
    map['tipo'] = Variable<String>(tipo);
    map['json'] = Variable<String>(json);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || syncError != null) {
      map['sync_error'] = Variable<String>(syncError);
    }
    map['actualizado'] = Variable<DateTime>(actualizado);
    return map;
  }

  MovimientosCompraLocalCompanion toCompanion(bool nullToAbsent) {
    return MovimientosCompraLocalCompanion(
      id: Value(id),
      loteId: Value(loteId),
      tipo: Value(tipo),
      json: Value(json),
      syncState: Value(syncState),
      syncError:
          syncError == null && nullToAbsent
              ? const Value.absent()
              : Value(syncError),
      actualizado: Value(actualizado),
    );
  }

  factory MovimientosCompraLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovimientosCompraLocalData(
      id: serializer.fromJson<String>(json['id']),
      loteId: serializer.fromJson<String>(json['loteId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      json: serializer.fromJson<String>(json['json']),
      syncState: serializer.fromJson<String>(json['syncState']),
      syncError: serializer.fromJson<String?>(json['syncError']),
      actualizado: serializer.fromJson<DateTime>(json['actualizado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loteId': serializer.toJson<String>(loteId),
      'tipo': serializer.toJson<String>(tipo),
      'json': serializer.toJson<String>(json),
      'syncState': serializer.toJson<String>(syncState),
      'syncError': serializer.toJson<String?>(syncError),
      'actualizado': serializer.toJson<DateTime>(actualizado),
    };
  }

  MovimientosCompraLocalData copyWith({
    String? id,
    String? loteId,
    String? tipo,
    String? json,
    String? syncState,
    Value<String?> syncError = const Value.absent(),
    DateTime? actualizado,
  }) => MovimientosCompraLocalData(
    id: id ?? this.id,
    loteId: loteId ?? this.loteId,
    tipo: tipo ?? this.tipo,
    json: json ?? this.json,
    syncState: syncState ?? this.syncState,
    syncError: syncError.present ? syncError.value : this.syncError,
    actualizado: actualizado ?? this.actualizado,
  );
  MovimientosCompraLocalData copyWithCompanion(
    MovimientosCompraLocalCompanion data,
  ) {
    return MovimientosCompraLocalData(
      id: data.id.present ? data.id.value : this.id,
      loteId: data.loteId.present ? data.loteId.value : this.loteId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      json: data.json.present ? data.json.value : this.json,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      syncError: data.syncError.present ? data.syncError.value : this.syncError,
      actualizado:
          data.actualizado.present ? data.actualizado.value : this.actualizado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCompraLocalData(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('tipo: $tipo, ')
          ..write('json: $json, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, loteId, tipo, json, syncState, syncError, actualizado);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovimientosCompraLocalData &&
          other.id == this.id &&
          other.loteId == this.loteId &&
          other.tipo == this.tipo &&
          other.json == this.json &&
          other.syncState == this.syncState &&
          other.syncError == this.syncError &&
          other.actualizado == this.actualizado);
}

class MovimientosCompraLocalCompanion
    extends UpdateCompanion<MovimientosCompraLocalData> {
  final Value<String> id;
  final Value<String> loteId;
  final Value<String> tipo;
  final Value<String> json;
  final Value<String> syncState;
  final Value<String?> syncError;
  final Value<DateTime> actualizado;
  final Value<int> rowid;
  const MovimientosCompraLocalCompanion({
    this.id = const Value.absent(),
    this.loteId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.json = const Value.absent(),
    this.syncState = const Value.absent(),
    this.syncError = const Value.absent(),
    this.actualizado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosCompraLocalCompanion.insert({
    required String id,
    required String loteId,
    required String tipo,
    required String json,
    required String syncState,
    this.syncError = const Value.absent(),
    required DateTime actualizado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loteId = Value(loteId),
       tipo = Value(tipo),
       json = Value(json),
       syncState = Value(syncState),
       actualizado = Value(actualizado);
  static Insertable<MovimientosCompraLocalData> custom({
    Expression<String>? id,
    Expression<String>? loteId,
    Expression<String>? tipo,
    Expression<String>? json,
    Expression<String>? syncState,
    Expression<String>? syncError,
    Expression<DateTime>? actualizado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loteId != null) 'lote_id': loteId,
      if (tipo != null) 'tipo': tipo,
      if (json != null) 'json': json,
      if (syncState != null) 'sync_state': syncState,
      if (syncError != null) 'sync_error': syncError,
      if (actualizado != null) 'actualizado': actualizado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosCompraLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? loteId,
    Value<String>? tipo,
    Value<String>? json,
    Value<String>? syncState,
    Value<String?>? syncError,
    Value<DateTime>? actualizado,
    Value<int>? rowid,
  }) {
    return MovimientosCompraLocalCompanion(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      tipo: tipo ?? this.tipo,
      json: json ?? this.json,
      syncState: syncState ?? this.syncState,
      syncError: syncError ?? this.syncError,
      actualizado: actualizado ?? this.actualizado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loteId.present) {
      map['lote_id'] = Variable<String>(loteId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (syncError.present) {
      map['sync_error'] = Variable<String>(syncError.value);
    }
    if (actualizado.present) {
      map['actualizado'] = Variable<DateTime>(actualizado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCompraLocalCompanion(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('tipo: $tipo, ')
          ..write('json: $json, ')
          ..write('syncState: $syncState, ')
          ..write('syncError: $syncError, ')
          ..write('actualizado: $actualizado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComprobantesLocalTable extends ComprobantesLocal
    with TableInfo<$ComprobantesLocalTable, ComprobantesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComprobantesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loteIdMeta = const VerificationMeta('loteId');
  @override
  late final GeneratedColumn<String> loteId = GeneratedColumn<String>(
    'lote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadMeta = const VerificationMeta(
    'entidad',
  );
  @override
  late final GeneratedColumn<String> entidad = GeneratedColumn<String>(
    'entidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadIdMeta = const VerificationMeta(
    'entidadId',
  );
  @override
  late final GeneratedColumn<String> entidadId = GeneratedColumn<String>(
    'entidad_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoMeta = const VerificationMeta('creado');
  @override
  late final GeneratedColumn<DateTime> creado = GeneratedColumn<DateTime>(
    'creado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loteId,
    entidad,
    entidadId,
    bytes,
    mime,
    syncState,
    creado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comprobantes_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComprobantesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lote_id')) {
      context.handle(
        _loteIdMeta,
        loteId.isAcceptableOrUnknown(data['lote_id']!, _loteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loteIdMeta);
    }
    if (data.containsKey('entidad')) {
      context.handle(
        _entidadMeta,
        entidad.isAcceptableOrUnknown(data['entidad']!, _entidadMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadMeta);
    }
    if (data.containsKey('entidad_id')) {
      context.handle(
        _entidadIdMeta,
        entidadId.isAcceptableOrUnknown(data['entidad_id']!, _entidadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadIdMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    } else if (isInserting) {
      context.missing(_syncStateMeta);
    }
    if (data.containsKey('creado')) {
      context.handle(
        _creadoMeta,
        creado.isAcceptableOrUnknown(data['creado']!, _creadoMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComprobantesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComprobantesLocalData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      loteId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}lote_id'],
          )!,
      entidad:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}entidad'],
          )!,
      entidadId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}entidad_id'],
          )!,
      bytes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.blob,
            data['${effectivePrefix}bytes'],
          )!,
      mime:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mime'],
          )!,
      syncState:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}sync_state'],
          )!,
      creado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}creado'],
          )!,
    );
  }

  @override
  $ComprobantesLocalTable createAlias(String alias) {
    return $ComprobantesLocalTable(attachedDatabase, alias);
  }
}

class ComprobantesLocalData extends DataClass
    implements Insertable<ComprobantesLocalData> {
  final String id;
  final String loteId;
  final String entidad;
  final String entidadId;
  final Uint8List bytes;
  final String mime;
  final String syncState;
  final DateTime creado;
  const ComprobantesLocalData({
    required this.id,
    required this.loteId,
    required this.entidad,
    required this.entidadId,
    required this.bytes,
    required this.mime,
    required this.syncState,
    required this.creado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lote_id'] = Variable<String>(loteId);
    map['entidad'] = Variable<String>(entidad);
    map['entidad_id'] = Variable<String>(entidadId);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['mime'] = Variable<String>(mime);
    map['sync_state'] = Variable<String>(syncState);
    map['creado'] = Variable<DateTime>(creado);
    return map;
  }

  ComprobantesLocalCompanion toCompanion(bool nullToAbsent) {
    return ComprobantesLocalCompanion(
      id: Value(id),
      loteId: Value(loteId),
      entidad: Value(entidad),
      entidadId: Value(entidadId),
      bytes: Value(bytes),
      mime: Value(mime),
      syncState: Value(syncState),
      creado: Value(creado),
    );
  }

  factory ComprobantesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComprobantesLocalData(
      id: serializer.fromJson<String>(json['id']),
      loteId: serializer.fromJson<String>(json['loteId']),
      entidad: serializer.fromJson<String>(json['entidad']),
      entidadId: serializer.fromJson<String>(json['entidadId']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      mime: serializer.fromJson<String>(json['mime']),
      syncState: serializer.fromJson<String>(json['syncState']),
      creado: serializer.fromJson<DateTime>(json['creado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loteId': serializer.toJson<String>(loteId),
      'entidad': serializer.toJson<String>(entidad),
      'entidadId': serializer.toJson<String>(entidadId),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'mime': serializer.toJson<String>(mime),
      'syncState': serializer.toJson<String>(syncState),
      'creado': serializer.toJson<DateTime>(creado),
    };
  }

  ComprobantesLocalData copyWith({
    String? id,
    String? loteId,
    String? entidad,
    String? entidadId,
    Uint8List? bytes,
    String? mime,
    String? syncState,
    DateTime? creado,
  }) => ComprobantesLocalData(
    id: id ?? this.id,
    loteId: loteId ?? this.loteId,
    entidad: entidad ?? this.entidad,
    entidadId: entidadId ?? this.entidadId,
    bytes: bytes ?? this.bytes,
    mime: mime ?? this.mime,
    syncState: syncState ?? this.syncState,
    creado: creado ?? this.creado,
  );
  ComprobantesLocalData copyWithCompanion(ComprobantesLocalCompanion data) {
    return ComprobantesLocalData(
      id: data.id.present ? data.id.value : this.id,
      loteId: data.loteId.present ? data.loteId.value : this.loteId,
      entidad: data.entidad.present ? data.entidad.value : this.entidad,
      entidadId: data.entidadId.present ? data.entidadId.value : this.entidadId,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      mime: data.mime.present ? data.mime.value : this.mime,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      creado: data.creado.present ? data.creado.value : this.creado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComprobantesLocalData(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('bytes: $bytes, ')
          ..write('mime: $mime, ')
          ..write('syncState: $syncState, ')
          ..write('creado: $creado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    loteId,
    entidad,
    entidadId,
    $driftBlobEquality.hash(bytes),
    mime,
    syncState,
    creado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComprobantesLocalData &&
          other.id == this.id &&
          other.loteId == this.loteId &&
          other.entidad == this.entidad &&
          other.entidadId == this.entidadId &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.mime == this.mime &&
          other.syncState == this.syncState &&
          other.creado == this.creado);
}

class ComprobantesLocalCompanion
    extends UpdateCompanion<ComprobantesLocalData> {
  final Value<String> id;
  final Value<String> loteId;
  final Value<String> entidad;
  final Value<String> entidadId;
  final Value<Uint8List> bytes;
  final Value<String> mime;
  final Value<String> syncState;
  final Value<DateTime> creado;
  final Value<int> rowid;
  const ComprobantesLocalCompanion({
    this.id = const Value.absent(),
    this.loteId = const Value.absent(),
    this.entidad = const Value.absent(),
    this.entidadId = const Value.absent(),
    this.bytes = const Value.absent(),
    this.mime = const Value.absent(),
    this.syncState = const Value.absent(),
    this.creado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComprobantesLocalCompanion.insert({
    required String id,
    required String loteId,
    required String entidad,
    required String entidadId,
    required Uint8List bytes,
    required String mime,
    required String syncState,
    required DateTime creado,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loteId = Value(loteId),
       entidad = Value(entidad),
       entidadId = Value(entidadId),
       bytes = Value(bytes),
       mime = Value(mime),
       syncState = Value(syncState),
       creado = Value(creado);
  static Insertable<ComprobantesLocalData> custom({
    Expression<String>? id,
    Expression<String>? loteId,
    Expression<String>? entidad,
    Expression<String>? entidadId,
    Expression<Uint8List>? bytes,
    Expression<String>? mime,
    Expression<String>? syncState,
    Expression<DateTime>? creado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loteId != null) 'lote_id': loteId,
      if (entidad != null) 'entidad': entidad,
      if (entidadId != null) 'entidad_id': entidadId,
      if (bytes != null) 'bytes': bytes,
      if (mime != null) 'mime': mime,
      if (syncState != null) 'sync_state': syncState,
      if (creado != null) 'creado': creado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComprobantesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? loteId,
    Value<String>? entidad,
    Value<String>? entidadId,
    Value<Uint8List>? bytes,
    Value<String>? mime,
    Value<String>? syncState,
    Value<DateTime>? creado,
    Value<int>? rowid,
  }) {
    return ComprobantesLocalCompanion(
      id: id ?? this.id,
      loteId: loteId ?? this.loteId,
      entidad: entidad ?? this.entidad,
      entidadId: entidadId ?? this.entidadId,
      bytes: bytes ?? this.bytes,
      mime: mime ?? this.mime,
      syncState: syncState ?? this.syncState,
      creado: creado ?? this.creado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loteId.present) {
      map['lote_id'] = Variable<String>(loteId.value);
    }
    if (entidad.present) {
      map['entidad'] = Variable<String>(entidad.value);
    }
    if (entidadId.present) {
      map['entidad_id'] = Variable<String>(entidadId.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (creado.present) {
      map['creado'] = Variable<DateTime>(creado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComprobantesLocalCompanion(')
          ..write('id: $id, ')
          ..write('loteId: $loteId, ')
          ..write('entidad: $entidad, ')
          ..write('entidadId: $entidadId, ')
          ..write('bytes: $bytes, ')
          ..write('mime: $mime, ')
          ..write('syncState: $syncState, ')
          ..write('creado: $creado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadIdMeta = const VerificationMeta(
    'entidadId',
  );
  @override
  late final GeneratedColumn<String> entidadId = GeneratedColumn<String>(
    'entidad_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bloqueadaMeta = const VerificationMeta(
    'bloqueada',
  );
  @override
  late final GeneratedColumn<bool> bloqueada = GeneratedColumn<bool>(
    'bloqueada',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bloqueada" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creadoMeta = const VerificationMeta('creado');
  @override
  late final GeneratedColumn<DateTime> creado = GeneratedColumn<DateTime>(
    'creado',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    tipo,
    entidadId,
    descripcion,
    payload,
    intentos,
    ultimoError,
    bloqueada,
    creado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('entidad_id')) {
      context.handle(
        _entidadIdMeta,
        entidadId.isAcceptableOrUnknown(data['entidad_id']!, _entidadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadIdMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    if (data.containsKey('bloqueada')) {
      context.handle(
        _bloqueadaMeta,
        bloqueada.isAcceptableOrUnknown(data['bloqueada']!, _bloqueadaMeta),
      );
    }
    if (data.containsKey('creado')) {
      context.handle(
        _creadoMeta,
        creado.isAcceptableOrUnknown(data['creado']!, _creadoMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}seq'],
          )!,
      tipo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tipo'],
          )!,
      entidadId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}entidad_id'],
          )!,
      descripcion:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}descripcion'],
          )!,
      payload:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}payload'],
          )!,
      intentos:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}intentos'],
          )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
      bloqueada:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}bloqueada'],
          )!,
      creado:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}creado'],
          )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int seq;
  final String tipo;
  final String entidadId;
  final String descripcion;
  final String payload;
  final int intentos;
  final String? ultimoError;
  final bool bloqueada;
  final DateTime creado;
  const OutboxData({
    required this.seq,
    required this.tipo,
    required this.entidadId,
    required this.descripcion,
    required this.payload,
    required this.intentos,
    this.ultimoError,
    required this.bloqueada,
    required this.creado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['tipo'] = Variable<String>(tipo);
    map['entidad_id'] = Variable<String>(entidadId);
    map['descripcion'] = Variable<String>(descripcion);
    map['payload'] = Variable<String>(payload);
    map['intentos'] = Variable<int>(intentos);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    map['bloqueada'] = Variable<bool>(bloqueada);
    map['creado'] = Variable<DateTime>(creado);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      tipo: Value(tipo),
      entidadId: Value(entidadId),
      descripcion: Value(descripcion),
      payload: Value(payload),
      intentos: Value(intentos),
      ultimoError:
          ultimoError == null && nullToAbsent
              ? const Value.absent()
              : Value(ultimoError),
      bloqueada: Value(bloqueada),
      creado: Value(creado),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      tipo: serializer.fromJson<String>(json['tipo']),
      entidadId: serializer.fromJson<String>(json['entidadId']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      payload: serializer.fromJson<String>(json['payload']),
      intentos: serializer.fromJson<int>(json['intentos']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      bloqueada: serializer.fromJson<bool>(json['bloqueada']),
      creado: serializer.fromJson<DateTime>(json['creado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'tipo': serializer.toJson<String>(tipo),
      'entidadId': serializer.toJson<String>(entidadId),
      'descripcion': serializer.toJson<String>(descripcion),
      'payload': serializer.toJson<String>(payload),
      'intentos': serializer.toJson<int>(intentos),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'bloqueada': serializer.toJson<bool>(bloqueada),
      'creado': serializer.toJson<DateTime>(creado),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? tipo,
    String? entidadId,
    String? descripcion,
    String? payload,
    int? intentos,
    Value<String?> ultimoError = const Value.absent(),
    bool? bloqueada,
    DateTime? creado,
  }) => OutboxData(
    seq: seq ?? this.seq,
    tipo: tipo ?? this.tipo,
    entidadId: entidadId ?? this.entidadId,
    descripcion: descripcion ?? this.descripcion,
    payload: payload ?? this.payload,
    intentos: intentos ?? this.intentos,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    bloqueada: bloqueada ?? this.bloqueada,
    creado: creado ?? this.creado,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      entidadId: data.entidadId.present ? data.entidadId.value : this.entidadId,
      descripcion:
          data.descripcion.present ? data.descripcion.value : this.descripcion,
      payload: data.payload.present ? data.payload.value : this.payload,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      ultimoError:
          data.ultimoError.present ? data.ultimoError.value : this.ultimoError,
      bloqueada: data.bloqueada.present ? data.bloqueada.value : this.bloqueada,
      creado: data.creado.present ? data.creado.value : this.creado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('tipo: $tipo, ')
          ..write('entidadId: $entidadId, ')
          ..write('descripcion: $descripcion, ')
          ..write('payload: $payload, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('bloqueada: $bloqueada, ')
          ..write('creado: $creado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    tipo,
    entidadId,
    descripcion,
    payload,
    intentos,
    ultimoError,
    bloqueada,
    creado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.tipo == this.tipo &&
          other.entidadId == this.entidadId &&
          other.descripcion == this.descripcion &&
          other.payload == this.payload &&
          other.intentos == this.intentos &&
          other.ultimoError == this.ultimoError &&
          other.bloqueada == this.bloqueada &&
          other.creado == this.creado);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> tipo;
  final Value<String> entidadId;
  final Value<String> descripcion;
  final Value<String> payload;
  final Value<int> intentos;
  final Value<String?> ultimoError;
  final Value<bool> bloqueada;
  final Value<DateTime> creado;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.tipo = const Value.absent(),
    this.entidadId = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.payload = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.bloqueada = const Value.absent(),
    this.creado = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String tipo,
    required String entidadId,
    required String descripcion,
    required String payload,
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.bloqueada = const Value.absent(),
    required DateTime creado,
  }) : tipo = Value(tipo),
       entidadId = Value(entidadId),
       descripcion = Value(descripcion),
       payload = Value(payload),
       creado = Value(creado);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? tipo,
    Expression<String>? entidadId,
    Expression<String>? descripcion,
    Expression<String>? payload,
    Expression<int>? intentos,
    Expression<String>? ultimoError,
    Expression<bool>? bloqueada,
    Expression<DateTime>? creado,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (tipo != null) 'tipo': tipo,
      if (entidadId != null) 'entidad_id': entidadId,
      if (descripcion != null) 'descripcion': descripcion,
      if (payload != null) 'payload': payload,
      if (intentos != null) 'intentos': intentos,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (bloqueada != null) 'bloqueada': bloqueada,
      if (creado != null) 'creado': creado,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? tipo,
    Value<String>? entidadId,
    Value<String>? descripcion,
    Value<String>? payload,
    Value<int>? intentos,
    Value<String?>? ultimoError,
    Value<bool>? bloqueada,
    Value<DateTime>? creado,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      tipo: tipo ?? this.tipo,
      entidadId: entidadId ?? this.entidadId,
      descripcion: descripcion ?? this.descripcion,
      payload: payload ?? this.payload,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
      bloqueada: bloqueada ?? this.bloqueada,
      creado: creado ?? this.creado,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (entidadId.present) {
      map['entidad_id'] = Variable<String>(entidadId.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (bloqueada.present) {
      map['bloqueada'] = Variable<bool>(bloqueada.value);
    }
    if (creado.present) {
      map['creado'] = Variable<DateTime>(creado.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('tipo: $tipo, ')
          ..write('entidadId: $entidadId, ')
          ..write('descripcion: $descripcion, ')
          ..write('payload: $payload, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('bloqueada: $bloqueada, ')
          ..write('creado: $creado')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KvEntriesTable kvEntries = $KvEntriesTable(this);
  late final $LotesLocalTable lotesLocal = $LotesLocalTable(this);
  late final $EvaluacionesLocalTable evaluacionesLocal =
      $EvaluacionesLocalTable(this);
  late final $EvidenciasLocalTable evidenciasLocal = $EvidenciasLocalTable(
    this,
  );
  late final $MovimientosCompraLocalTable movimientosCompraLocal =
      $MovimientosCompraLocalTable(this);
  late final $ComprobantesLocalTable comprobantesLocal =
      $ComprobantesLocalTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    kvEntries,
    lotesLocal,
    evaluacionesLocal,
    evidenciasLocal,
    movimientosCompraLocal,
    comprobantesLocal,
    outbox,
  ];
}

typedef $$KvEntriesTableCreateCompanionBuilder =
    KvEntriesCompanion Function({
      required String clave,
      required String valor,
      required DateTime actualizado,
      Value<int> rowid,
    });
typedef $$KvEntriesTableUpdateCompanionBuilder =
    KvEntriesCompanion Function({
      Value<String> clave,
      Value<String> valor,
      Value<DateTime> actualizado,
      Value<int> rowid,
    });

class $$KvEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KvEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KvEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KvEntriesTable> {
  $$KvEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );
}

class $$KvEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KvEntriesTable,
          KvEntry,
          $$KvEntriesTableFilterComposer,
          $$KvEntriesTableOrderingComposer,
          $$KvEntriesTableAnnotationComposer,
          $$KvEntriesTableCreateCompanionBuilder,
          $$KvEntriesTableUpdateCompanionBuilder,
          (KvEntry, BaseReferences<_$AppDatabase, $KvEntriesTable, KvEntry>),
          KvEntry,
          PrefetchHooks Function()
        > {
  $$KvEntriesTableTableManager(_$AppDatabase db, $KvEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$KvEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$KvEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$KvEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clave = const Value.absent(),
                Value<String> valor = const Value.absent(),
                Value<DateTime> actualizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion(
                clave: clave,
                valor: valor,
                actualizado: actualizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                required DateTime actualizado,
                Value<int> rowid = const Value.absent(),
              }) => KvEntriesCompanion.insert(
                clave: clave,
                valor: valor,
                actualizado: actualizado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KvEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KvEntriesTable,
      KvEntry,
      $$KvEntriesTableFilterComposer,
      $$KvEntriesTableOrderingComposer,
      $$KvEntriesTableAnnotationComposer,
      $$KvEntriesTableCreateCompanionBuilder,
      $$KvEntriesTableUpdateCompanionBuilder,
      (KvEntry, BaseReferences<_$AppDatabase, $KvEntriesTable, KvEntry>),
      KvEntry,
      PrefetchHooks Function()
    >;
typedef $$LotesLocalTableCreateCompanionBuilder =
    LotesLocalCompanion Function({
      required String id,
      required String json,
      required String codigo,
      required String zona,
      required String agricultor,
      required String estado,
      required String syncState,
      Value<String?> syncError,
      required DateTime actualizado,
      Value<int> rowid,
    });
typedef $$LotesLocalTableUpdateCompanionBuilder =
    LotesLocalCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<String> codigo,
      Value<String> zona,
      Value<String> agricultor,
      Value<String> estado,
      Value<String> syncState,
      Value<String?> syncError,
      Value<DateTime> actualizado,
      Value<int> rowid,
    });

class $$LotesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agricultor => $composableBuilder(
    column: $table.agricultor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LotesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get zona => $composableBuilder(
    column: $table.zona,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agricultor => $composableBuilder(
    column: $table.agricultor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LotesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $LotesLocalTable> {
  $$LotesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get zona =>
      $composableBuilder(column: $table.zona, builder: (column) => column);

  GeneratedColumn<String> get agricultor => $composableBuilder(
    column: $table.agricultor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );
}

class $$LotesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LotesLocalTable,
          LotesLocalData,
          $$LotesLocalTableFilterComposer,
          $$LotesLocalTableOrderingComposer,
          $$LotesLocalTableAnnotationComposer,
          $$LotesLocalTableCreateCompanionBuilder,
          $$LotesLocalTableUpdateCompanionBuilder,
          (
            LotesLocalData,
            BaseReferences<_$AppDatabase, $LotesLocalTable, LotesLocalData>,
          ),
          LotesLocalData,
          PrefetchHooks Function()
        > {
  $$LotesLocalTableTableManager(_$AppDatabase db, $LotesLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LotesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LotesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LotesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> zona = const Value.absent(),
                Value<String> agricultor = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> actualizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LotesLocalCompanion(
                id: id,
                json: json,
                codigo: codigo,
                zona: zona,
                agricultor: agricultor,
                estado: estado,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String codigo,
                required String zona,
                required String agricultor,
                required String estado,
                required String syncState,
                Value<String?> syncError = const Value.absent(),
                required DateTime actualizado,
                Value<int> rowid = const Value.absent(),
              }) => LotesLocalCompanion.insert(
                id: id,
                json: json,
                codigo: codigo,
                zona: zona,
                agricultor: agricultor,
                estado: estado,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LotesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LotesLocalTable,
      LotesLocalData,
      $$LotesLocalTableFilterComposer,
      $$LotesLocalTableOrderingComposer,
      $$LotesLocalTableAnnotationComposer,
      $$LotesLocalTableCreateCompanionBuilder,
      $$LotesLocalTableUpdateCompanionBuilder,
      (
        LotesLocalData,
        BaseReferences<_$AppDatabase, $LotesLocalTable, LotesLocalData>,
      ),
      LotesLocalData,
      PrefetchHooks Function()
    >;
typedef $$EvaluacionesLocalTableCreateCompanionBuilder =
    EvaluacionesLocalCompanion Function({
      required String id,
      required String loteId,
      required String resumenJson,
      Value<String?> borradorJson,
      required String estado,
      required DateTime fecha,
      required String syncState,
      Value<String?> syncError,
      required DateTime actualizado,
      Value<int> rowid,
    });
typedef $$EvaluacionesLocalTableUpdateCompanionBuilder =
    EvaluacionesLocalCompanion Function({
      Value<String> id,
      Value<String> loteId,
      Value<String> resumenJson,
      Value<String?> borradorJson,
      Value<String> estado,
      Value<DateTime> fecha,
      Value<String> syncState,
      Value<String?> syncError,
      Value<DateTime> actualizado,
      Value<int> rowid,
    });

class $$EvaluacionesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $EvaluacionesLocalTable> {
  $$EvaluacionesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumenJson => $composableBuilder(
    column: $table.resumenJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borradorJson => $composableBuilder(
    column: $table.borradorJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EvaluacionesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $EvaluacionesLocalTable> {
  $$EvaluacionesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumenJson => $composableBuilder(
    column: $table.resumenJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borradorJson => $composableBuilder(
    column: $table.borradorJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EvaluacionesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvaluacionesLocalTable> {
  $$EvaluacionesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loteId =>
      $composableBuilder(column: $table.loteId, builder: (column) => column);

  GeneratedColumn<String> get resumenJson => $composableBuilder(
    column: $table.resumenJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borradorJson => $composableBuilder(
    column: $table.borradorJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );
}

class $$EvaluacionesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvaluacionesLocalTable,
          EvaluacionesLocalData,
          $$EvaluacionesLocalTableFilterComposer,
          $$EvaluacionesLocalTableOrderingComposer,
          $$EvaluacionesLocalTableAnnotationComposer,
          $$EvaluacionesLocalTableCreateCompanionBuilder,
          $$EvaluacionesLocalTableUpdateCompanionBuilder,
          (
            EvaluacionesLocalData,
            BaseReferences<
              _$AppDatabase,
              $EvaluacionesLocalTable,
              EvaluacionesLocalData
            >,
          ),
          EvaluacionesLocalData,
          PrefetchHooks Function()
        > {
  $$EvaluacionesLocalTableTableManager(
    _$AppDatabase db,
    $EvaluacionesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$EvaluacionesLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$EvaluacionesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$EvaluacionesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loteId = const Value.absent(),
                Value<String> resumenJson = const Value.absent(),
                Value<String?> borradorJson = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> actualizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvaluacionesLocalCompanion(
                id: id,
                loteId: loteId,
                resumenJson: resumenJson,
                borradorJson: borradorJson,
                estado: estado,
                fecha: fecha,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loteId,
                required String resumenJson,
                Value<String?> borradorJson = const Value.absent(),
                required String estado,
                required DateTime fecha,
                required String syncState,
                Value<String?> syncError = const Value.absent(),
                required DateTime actualizado,
                Value<int> rowid = const Value.absent(),
              }) => EvaluacionesLocalCompanion.insert(
                id: id,
                loteId: loteId,
                resumenJson: resumenJson,
                borradorJson: borradorJson,
                estado: estado,
                fecha: fecha,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EvaluacionesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvaluacionesLocalTable,
      EvaluacionesLocalData,
      $$EvaluacionesLocalTableFilterComposer,
      $$EvaluacionesLocalTableOrderingComposer,
      $$EvaluacionesLocalTableAnnotationComposer,
      $$EvaluacionesLocalTableCreateCompanionBuilder,
      $$EvaluacionesLocalTableUpdateCompanionBuilder,
      (
        EvaluacionesLocalData,
        BaseReferences<
          _$AppDatabase,
          $EvaluacionesLocalTable,
          EvaluacionesLocalData
        >,
      ),
      EvaluacionesLocalData,
      PrefetchHooks Function()
    >;
typedef $$EvidenciasLocalTableCreateCompanionBuilder =
    EvidenciasLocalCompanion Function({
      required String id,
      required String evaluacionId,
      Value<int?> muestraNumero,
      Value<String?> factor,
      required Uint8List bytes,
      required String mime,
      required String syncState,
      required DateTime creado,
      Value<int> rowid,
    });
typedef $$EvidenciasLocalTableUpdateCompanionBuilder =
    EvidenciasLocalCompanion Function({
      Value<String> id,
      Value<String> evaluacionId,
      Value<int?> muestraNumero,
      Value<String?> factor,
      Value<Uint8List> bytes,
      Value<String> mime,
      Value<String> syncState,
      Value<DateTime> creado,
      Value<int> rowid,
    });

class $$EvidenciasLocalTableFilterComposer
    extends Composer<_$AppDatabase, $EvidenciasLocalTable> {
  $$EvidenciasLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evaluacionId => $composableBuilder(
    column: $table.evaluacionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get muestraNumero => $composableBuilder(
    column: $table.muestraNumero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EvidenciasLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $EvidenciasLocalTable> {
  $$EvidenciasLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evaluacionId => $composableBuilder(
    column: $table.evaluacionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get muestraNumero => $composableBuilder(
    column: $table.muestraNumero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EvidenciasLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $EvidenciasLocalTable> {
  $$EvidenciasLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get evaluacionId => $composableBuilder(
    column: $table.evaluacionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get muestraNumero => $composableBuilder(
    column: $table.muestraNumero,
    builder: (column) => column,
  );

  GeneratedColumn<String> get factor =>
      $composableBuilder(column: $table.factor, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get creado =>
      $composableBuilder(column: $table.creado, builder: (column) => column);
}

class $$EvidenciasLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EvidenciasLocalTable,
          EvidenciasLocalData,
          $$EvidenciasLocalTableFilterComposer,
          $$EvidenciasLocalTableOrderingComposer,
          $$EvidenciasLocalTableAnnotationComposer,
          $$EvidenciasLocalTableCreateCompanionBuilder,
          $$EvidenciasLocalTableUpdateCompanionBuilder,
          (
            EvidenciasLocalData,
            BaseReferences<
              _$AppDatabase,
              $EvidenciasLocalTable,
              EvidenciasLocalData
            >,
          ),
          EvidenciasLocalData,
          PrefetchHooks Function()
        > {
  $$EvidenciasLocalTableTableManager(
    _$AppDatabase db,
    $EvidenciasLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$EvidenciasLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$EvidenciasLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$EvidenciasLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> evaluacionId = const Value.absent(),
                Value<int?> muestraNumero = const Value.absent(),
                Value<String?> factor = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> creado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EvidenciasLocalCompanion(
                id: id,
                evaluacionId: evaluacionId,
                muestraNumero: muestraNumero,
                factor: factor,
                bytes: bytes,
                mime: mime,
                syncState: syncState,
                creado: creado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String evaluacionId,
                Value<int?> muestraNumero = const Value.absent(),
                Value<String?> factor = const Value.absent(),
                required Uint8List bytes,
                required String mime,
                required String syncState,
                required DateTime creado,
                Value<int> rowid = const Value.absent(),
              }) => EvidenciasLocalCompanion.insert(
                id: id,
                evaluacionId: evaluacionId,
                muestraNumero: muestraNumero,
                factor: factor,
                bytes: bytes,
                mime: mime,
                syncState: syncState,
                creado: creado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EvidenciasLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EvidenciasLocalTable,
      EvidenciasLocalData,
      $$EvidenciasLocalTableFilterComposer,
      $$EvidenciasLocalTableOrderingComposer,
      $$EvidenciasLocalTableAnnotationComposer,
      $$EvidenciasLocalTableCreateCompanionBuilder,
      $$EvidenciasLocalTableUpdateCompanionBuilder,
      (
        EvidenciasLocalData,
        BaseReferences<
          _$AppDatabase,
          $EvidenciasLocalTable,
          EvidenciasLocalData
        >,
      ),
      EvidenciasLocalData,
      PrefetchHooks Function()
    >;
typedef $$MovimientosCompraLocalTableCreateCompanionBuilder =
    MovimientosCompraLocalCompanion Function({
      required String id,
      required String loteId,
      required String tipo,
      required String json,
      required String syncState,
      Value<String?> syncError,
      required DateTime actualizado,
      Value<int> rowid,
    });
typedef $$MovimientosCompraLocalTableUpdateCompanionBuilder =
    MovimientosCompraLocalCompanion Function({
      Value<String> id,
      Value<String> loteId,
      Value<String> tipo,
      Value<String> json,
      Value<String> syncState,
      Value<String?> syncError,
      Value<DateTime> actualizado,
      Value<int> rowid,
    });

class $$MovimientosCompraLocalTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosCompraLocalTable> {
  $$MovimientosCompraLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovimientosCompraLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosCompraLocalTable> {
  $$MovimientosCompraLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncError => $composableBuilder(
    column: $table.syncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovimientosCompraLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosCompraLocalTable> {
  $$MovimientosCompraLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loteId =>
      $composableBuilder(column: $table.loteId, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get syncError =>
      $composableBuilder(column: $table.syncError, builder: (column) => column);

  GeneratedColumn<DateTime> get actualizado => $composableBuilder(
    column: $table.actualizado,
    builder: (column) => column,
  );
}

class $$MovimientosCompraLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosCompraLocalTable,
          MovimientosCompraLocalData,
          $$MovimientosCompraLocalTableFilterComposer,
          $$MovimientosCompraLocalTableOrderingComposer,
          $$MovimientosCompraLocalTableAnnotationComposer,
          $$MovimientosCompraLocalTableCreateCompanionBuilder,
          $$MovimientosCompraLocalTableUpdateCompanionBuilder,
          (
            MovimientosCompraLocalData,
            BaseReferences<
              _$AppDatabase,
              $MovimientosCompraLocalTable,
              MovimientosCompraLocalData
            >,
          ),
          MovimientosCompraLocalData,
          PrefetchHooks Function()
        > {
  $$MovimientosCompraLocalTableTableManager(
    _$AppDatabase db,
    $MovimientosCompraLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$MovimientosCompraLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$MovimientosCompraLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$MovimientosCompraLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loteId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> syncError = const Value.absent(),
                Value<DateTime> actualizado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompraLocalCompanion(
                id: id,
                loteId: loteId,
                tipo: tipo,
                json: json,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loteId,
                required String tipo,
                required String json,
                required String syncState,
                Value<String?> syncError = const Value.absent(),
                required DateTime actualizado,
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompraLocalCompanion.insert(
                id: id,
                loteId: loteId,
                tipo: tipo,
                json: json,
                syncState: syncState,
                syncError: syncError,
                actualizado: actualizado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovimientosCompraLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosCompraLocalTable,
      MovimientosCompraLocalData,
      $$MovimientosCompraLocalTableFilterComposer,
      $$MovimientosCompraLocalTableOrderingComposer,
      $$MovimientosCompraLocalTableAnnotationComposer,
      $$MovimientosCompraLocalTableCreateCompanionBuilder,
      $$MovimientosCompraLocalTableUpdateCompanionBuilder,
      (
        MovimientosCompraLocalData,
        BaseReferences<
          _$AppDatabase,
          $MovimientosCompraLocalTable,
          MovimientosCompraLocalData
        >,
      ),
      MovimientosCompraLocalData,
      PrefetchHooks Function()
    >;
typedef $$ComprobantesLocalTableCreateCompanionBuilder =
    ComprobantesLocalCompanion Function({
      required String id,
      required String loteId,
      required String entidad,
      required String entidadId,
      required Uint8List bytes,
      required String mime,
      required String syncState,
      required DateTime creado,
      Value<int> rowid,
    });
typedef $$ComprobantesLocalTableUpdateCompanionBuilder =
    ComprobantesLocalCompanion Function({
      Value<String> id,
      Value<String> loteId,
      Value<String> entidad,
      Value<String> entidadId,
      Value<Uint8List> bytes,
      Value<String> mime,
      Value<String> syncState,
      Value<DateTime> creado,
      Value<int> rowid,
    });

class $$ComprobantesLocalTableFilterComposer
    extends Composer<_$AppDatabase, $ComprobantesLocalTable> {
  $$ComprobantesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ComprobantesLocalTableOrderingComposer
    extends Composer<_$AppDatabase, $ComprobantesLocalTable> {
  $$ComprobantesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loteId => $composableBuilder(
    column: $table.loteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ComprobantesLocalTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComprobantesLocalTable> {
  $$ComprobantesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loteId =>
      $composableBuilder(column: $table.loteId, builder: (column) => column);

  GeneratedColumn<String> get entidad =>
      $composableBuilder(column: $table.entidad, builder: (column) => column);

  GeneratedColumn<String> get entidadId =>
      $composableBuilder(column: $table.entidadId, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get creado =>
      $composableBuilder(column: $table.creado, builder: (column) => column);
}

class $$ComprobantesLocalTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComprobantesLocalTable,
          ComprobantesLocalData,
          $$ComprobantesLocalTableFilterComposer,
          $$ComprobantesLocalTableOrderingComposer,
          $$ComprobantesLocalTableAnnotationComposer,
          $$ComprobantesLocalTableCreateCompanionBuilder,
          $$ComprobantesLocalTableUpdateCompanionBuilder,
          (
            ComprobantesLocalData,
            BaseReferences<
              _$AppDatabase,
              $ComprobantesLocalTable,
              ComprobantesLocalData
            >,
          ),
          ComprobantesLocalData,
          PrefetchHooks Function()
        > {
  $$ComprobantesLocalTableTableManager(
    _$AppDatabase db,
    $ComprobantesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ComprobantesLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$ComprobantesLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$ComprobantesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loteId = const Value.absent(),
                Value<String> entidad = const Value.absent(),
                Value<String> entidadId = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<String> mime = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<DateTime> creado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComprobantesLocalCompanion(
                id: id,
                loteId: loteId,
                entidad: entidad,
                entidadId: entidadId,
                bytes: bytes,
                mime: mime,
                syncState: syncState,
                creado: creado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loteId,
                required String entidad,
                required String entidadId,
                required Uint8List bytes,
                required String mime,
                required String syncState,
                required DateTime creado,
                Value<int> rowid = const Value.absent(),
              }) => ComprobantesLocalCompanion.insert(
                id: id,
                loteId: loteId,
                entidad: entidad,
                entidadId: entidadId,
                bytes: bytes,
                mime: mime,
                syncState: syncState,
                creado: creado,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ComprobantesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComprobantesLocalTable,
      ComprobantesLocalData,
      $$ComprobantesLocalTableFilterComposer,
      $$ComprobantesLocalTableOrderingComposer,
      $$ComprobantesLocalTableAnnotationComposer,
      $$ComprobantesLocalTableCreateCompanionBuilder,
      $$ComprobantesLocalTableUpdateCompanionBuilder,
      (
        ComprobantesLocalData,
        BaseReferences<
          _$AppDatabase,
          $ComprobantesLocalTable,
          ComprobantesLocalData
        >,
      ),
      ComprobantesLocalData,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      required String tipo,
      required String entidadId,
      required String descripcion,
      required String payload,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<bool> bloqueada,
      required DateTime creado,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<int> seq,
      Value<String> tipo,
      Value<String> entidadId,
      Value<String> descripcion,
      Value<String> payload,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<bool> bloqueada,
      Value<DateTime> creado,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bloqueada => $composableBuilder(
    column: $table.bloqueada,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadId => $composableBuilder(
    column: $table.entidadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bloqueada => $composableBuilder(
    column: $table.bloqueada,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creado => $composableBuilder(
    column: $table.creado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get entidadId =>
      $composableBuilder(column: $table.entidadId, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bloqueada =>
      $composableBuilder(column: $table.bloqueada, builder: (column) => column);

  GeneratedColumn<DateTime> get creado =>
      $composableBuilder(column: $table.creado, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> entidadId = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<bool> bloqueada = const Value.absent(),
                Value<DateTime> creado = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                tipo: tipo,
                entidadId: entidadId,
                descripcion: descripcion,
                payload: payload,
                intentos: intentos,
                ultimoError: ultimoError,
                bloqueada: bloqueada,
                creado: creado,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String tipo,
                required String entidadId,
                required String descripcion,
                required String payload,
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<bool> bloqueada = const Value.absent(),
                required DateTime creado,
              }) => OutboxCompanion.insert(
                seq: seq,
                tipo: tipo,
                entidadId: entidadId,
                descripcion: descripcion,
                payload: payload,
                intentos: intentos,
                ultimoError: ultimoError,
                bloqueada: bloqueada,
                creado: creado,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KvEntriesTableTableManager get kvEntries =>
      $$KvEntriesTableTableManager(_db, _db.kvEntries);
  $$LotesLocalTableTableManager get lotesLocal =>
      $$LotesLocalTableTableManager(_db, _db.lotesLocal);
  $$EvaluacionesLocalTableTableManager get evaluacionesLocal =>
      $$EvaluacionesLocalTableTableManager(_db, _db.evaluacionesLocal);
  $$EvidenciasLocalTableTableManager get evidenciasLocal =>
      $$EvidenciasLocalTableTableManager(_db, _db.evidenciasLocal);
  $$MovimientosCompraLocalTableTableManager get movimientosCompraLocal =>
      $$MovimientosCompraLocalTableTableManager(
        _db,
        _db.movimientosCompraLocal,
      );
  $$ComprobantesLocalTableTableManager get comprobantesLocal =>
      $$ComprobantesLocalTableTableManager(_db, _db.comprobantesLocal);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
}
