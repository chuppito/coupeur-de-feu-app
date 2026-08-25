// GENERATED CODE - DO NOT MODIFY BY HAND
// (écrit à la main sur le même modèle que protocole.g.dart)

part of 'cadran.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CadranAdapter extends TypeAdapter<Cadran> {
  @override
  final int typeId = 2;

  @override
  Cadran read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cadran(
      titre: fields[0] as String,
      cheminImage: fields[1] == null ? '' : fields[1] as String,
      dateAjout: fields[2] as DateTime,
      type: fields[3] == null ? 'image' : fields[3] as String,
      labels: (fields[4] as List?)?.cast<String>(),
      attribution: fields[5] as String?,
      groupes: (fields[6] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Cadran obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.cheminImage)
      ..writeByte(2)
      ..write(obj.dateAjout)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.labels)
      ..writeByte(5)
      ..write(obj.attribution)
      ..writeByte(6)
      ..write(obj.groupes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CadranAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
