// GENERATED CODE - DO NOT MODIFY BY HAND
// (écrit à la main sur le même modèle que patient_session.g.dart ;
// si tu régénères avec build_runner plus tard, ce fichier sera remplacé
// sans rien casser tant que les @HiveField restent identiques)

part of 'protocole.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProtocoleAdapter extends TypeAdapter<Protocole> {
  @override
  final int typeId = 1;

  @override
  Protocole read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Protocole(
      titre: fields[0] as String,
      priere: fields[1] == null ? '' : fields[1] as String,
      etapes: fields[2] == null ? '' : fields[2] as String,
      dateAjout: fields[3] as DateTime,
      estParDefaut: fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Protocole obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.titre)
      ..writeByte(1)
      ..write(obj.priere)
      ..writeByte(2)
      ..write(obj.etapes)
      ..writeByte(3)
      ..write(obj.dateAjout)
      ..writeByte(4)
      ..write(obj.estParDefaut);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProtocoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
