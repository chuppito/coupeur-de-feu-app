import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MagnetismeSessionService {
  static const String boxName = 'magnetisme_sessions';
  static Box get _box => Hive.box(boxName);
  static ValueListenable<Box> listenable() => _box.listenable();
  static Future<void> save(Map<String,dynamic> value) async => _box.add(Map<String,dynamic>.from(value));

  static List<Map<String,dynamic>> getForPatient(String fullName) {
    final list=_box.toMap().entries.where((e)=>e.value is Map).map((e){
      final v=Map<String,dynamic>.from(e.value as Map); v['_hiveKey']=e.key; return v;
    }).where((v){
      final p=(v['nomPatient']??'').toString().trim(), n=(v['nomFamille']??'').toString().trim();
      return (n.isEmpty?p:p+' '+n)==fullName;
    }).toList();
    list.sort((a,b){
      final da=DateTime.tryParse((a['date']??'').toString())??DateTime(1970);
      final db=DateTime.tryParse((b['date']??'').toString())??DateTime(1970);
      return db.compareTo(da);
    });
    return list;
  }

  static Future<void> renamePatient(String oldName,String first,String last) async {
    for(final e in _box.toMap().entries){
      if(e.value is! Map)continue;
      final v=Map<String,dynamic>.from(e.value as Map);
      final p=(v['nomPatient']??'').toString().trim(),n=(v['nomFamille']??'').toString().trim();
      if((n.isEmpty?p:p+' '+n)==oldName){v['nomPatient']=first.trim();v['nomFamille']=last.trim();await _box.put(e.key,v);}
    }
  }

  static Future<List<Map<String,dynamic>>> deletePatient(String fullName) async {
    final es=_box.toMap().entries.where((e){
      if(e.value is! Map)return false;
      final v=e.value as Map,p=(v['nomPatient']??'').toString().trim(),n=(v['nomFamille']??'').toString().trim();
      return (n.isEmpty?p:p+' '+n)==fullName;
    }).toList();
    final snap=es.map((e)=>Map<String,dynamic>.from(e.value as Map)).toList();
    await _box.deleteAll(es.map((e)=>e.key).toList()); return snap;
  }

  static Future<void> restore(List<Map<String,dynamic>> values) async {for(final v in values)await _box.add(Map<String,dynamic>.from(v));}
  static Future<void> deleteByKey(dynamic key)=>_box.delete(key);
  static String exportAllToJson()=>const JsonEncoder.withIndent('  ').convert(_box.values.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList());
  static Future<int> importFromJson(String content) async {
    final d=jsonDecode(content); if(d is! List)throw const FormatException('Format de séances de magnétisme invalide.');
    var n=0; for(final v in d){if(v is Map){await _box.add(Map<String,dynamic>.from(v));n++;}} return n;
  }
}