import 'dart:async';
import 'package:flutter/material.dart';

/// A local action uses exactly the duration supplied by the source-backed model.
/// Completion is explicit: no automatic advancement across an unknown duration.
class ProtocolTimer extends StatefulWidget {
  final int seconds;
  final int? initialRemaining;
  final ValueChanged<int>? onChanged;
  const ProtocolTimer({super.key,required this.seconds,this.initialRemaining,this.onChanged});
  @override
  State<ProtocolTimer> createState()=>_ProtocolTimerState();
}
class _ProtocolTimerState extends State<ProtocolTimer> with WidgetsBindingObserver {
  late int remaining;
  Timer? timer;
  bool running=false;
  @override
  void initState(){super.initState();remaining=(widget.initialRemaining??widget.seconds).clamp(0,widget.seconds);WidgetsBinding.instance.addObserver(this);}
  @override
  void dispose(){timer?.cancel();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){if(state!=AppLifecycleState.resumed)pause();}
  void pause(){timer?.cancel();if(mounted)setState(()=>running=false);}
  void start(){
    if(remaining==0)return;
    setState(()=>running=true);
    timer?.cancel();timer=Timer.periodic(const Duration(seconds:1),(t){
      if(!mounted){t.cancel();return;}
      setState(()=>remaining--);
      widget.onChanged?.call(remaining);
      if(remaining==0)pause();
    });
  }
  @override
  Widget build(BuildContext context)=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('${remaining~/60}:${(remaining%60).toString().padLeft(2,'0')}',style:Theme.of(context).textTheme.headlineMedium),
    Text('Durée documentée : ${widget.seconds} secondes. Minuteur silencieux.'),
    Wrap(spacing:8,children:[
      OutlinedButton(onPressed:remaining==0?null:running?pause:start,child:Text(running?'Pause locale':remaining==widget.seconds?'Démarrer le minuteur':'Reprendre le minuteur')),
      TextButton(onPressed:(){pause();setState(()=>remaining=widget.seconds);widget.onChanged?.call(remaining);},child:const Text('Réinitialiser le minuteur')),
    ]),
    if(remaining==0)const Text('Durée écoulée. Validez le travail avant de passer à la suite.'),
  ]);
}
