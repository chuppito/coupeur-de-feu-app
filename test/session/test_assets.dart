import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
/// Même contenu versionné que l'application ; seul le transport plateforme est substitué.
class TestAssets extends CachingAssetBundle {
  final Map<String,Uint8List> files={
    for(final name in ['magnetisme_protocoles.json','magnetisme_techniques.json','magnetisme_techniques_chakras.json','guide_v33.json','advice_v332.json','legacy_thot_v332.json'])
      'assets/data/$name':File('assets/data/$name').readAsBytesSync(),
  };
  @override
  Future<String> loadString(String key,{bool cache=true}) async => utf8.decode(files[key]!);
  @override
  Future<ByteData> load(String key) async => ByteData.sublistView(files[key]!);
}
