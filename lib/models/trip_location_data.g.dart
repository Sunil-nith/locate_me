// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_location_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripLocationDataAdapter extends TypeAdapter<TripLocationData> {
  @override
  final int typeId = 2;

  @override
  TripLocationData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripLocationData(
      previousLoc: fields[0] as String,
      currentLoc: fields[1] as String,
      distance: fields[2] as double,
      tripId: fields[3] as String,
      userId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TripLocationData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.previousLoc)
      ..writeByte(1)
      ..write(obj.currentLoc)
      ..writeByte(2)
      ..write(obj.distance)
      ..writeByte(3)
      ..write(obj.tripId)
      ..writeByte(4)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLocationDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
