import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/widgets/protocol_timer.dart';
void main(){
  testWidgets('Durée unique, pause/reprise et arrêt à zéro, sans passage implicite', (t)async{
    await t.pumpWidget(const MaterialApp(home:Scaffold(body:ProtocolTimer(seconds:120))));
    expect(find.text('2:00'),findsOneWidget);
    await t.tap(find.text('Démarrer le minuteur'));await t.pump(const Duration(seconds:2));
    expect(find.text('1:58'),findsOneWidget);
    await t.tap(find.text('Pause locale'));await t.pump(const Duration(seconds:10));
    expect(find.text('1:58'),findsOneWidget);
    await t.tap(find.text('Reprendre le minuteur'));await t.pump(const Duration(seconds:118));
    expect(find.text('0:00'),findsOneWidget);expect(find.textContaining('Durée écoulée'),findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
