import 'package:flutter/material.dart';

class TrainerAdvice extends StatelessWidget {
  final List<dynamic> items;
  final String title;
  final bool initiallyExpanded;
  const TrainerAdvice({super.key,required this.items,this.title='Conseils du formateur',this.initiallyExpanded=false});
  @override
  Widget build(BuildContext context){
    if(items.isEmpty)return const SizedBox.shrink();
    return ExpansionTile(
      title:Text(title),initiallyExpanded:initiallyExpanded,
      childrenPadding:const EdgeInsets.fromLTRB(16,0,16,12),
      expandedCrossAxisAlignment:CrossAxisAlignment.start,
      children:[
        const Text('Propos de la formation : pratiques traditionnelles, pas des recommandations médicales. Ne remplacent pas les soins médicaux.'),
        for(final raw in items) ...[
          const SizedBox(height:10),
          SelectableText((raw as Map)['text'].toString()),
          ExpansionTile(title:const Text('Source du conseil'),children:[
            SelectableText(raw['source'].toString()),
            if(raw['lesson']!=null)SelectableText(raw['lesson'].toString()),
            if(raw['video']!=null)SelectableText(raw['video'].toString()),
            if(raw['time']!=null)Text('Repères : ${raw['time']}'),
            Text(raw['method']?.toString()??'Document écrit.'),
          ]),
        ],
      ],
    );
  }
}
