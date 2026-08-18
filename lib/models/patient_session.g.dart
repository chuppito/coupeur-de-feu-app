// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientSessionAdapter extends TypeAdapter<PatientSession> {
  @override
  final int typeId = 0;

  @override
  PatientSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientSession(
      nomPatient: fields[0] as String,
      zone: fields[1] as String,
      observation: fields[2] as String,
      intensiteAvant: fields[3] as int?,
      intensiteApres: fields[4] as int?,
      date: fields[5] as DateTime,
      maladie: fields[6] == null ? '' : fields[6] as String,
      guerie: fields[7] == null ? false : fields[7] as bool,
      dateGuerison: fields[8] as DateTime?,
      nomFamille: fields[9] == null ? '' : fields[9] as String,
      protocoleTitre: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatientSession obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.nomPatient)
      ..writeByte(1)
      ..write(obj.zone)
      ..writeByte(2)
      ..write(obj.observation)
      ..writeByte(3)
      ..write(obj.intensiteAvant)
      ..writeByte(4)
      ..write(obj.intensiteApres)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.maladie)
      ..writeByte(7)
      ..write(obj.guerie)
      ..writeByte(8)
      ..write(obj.dateGuerison)
      ..writeByte(9)
      ..write(obj.nomFamille)
      ..writeByte(10)
      ..write(obj.protocoleTitre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
