import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/dev/provider_preview/main.dart' as preview;
void main(){
 setUpAll(()=>GoogleFonts.config.allowRuntimeFetching=false);
 for(final individual in [true,false]){
  for(final size in [const Size(360,800),const Size(1280,600),const Size(1280,420)]){
   testWidgets('audit ${individual?'individual':'org'} ${size.width} height ${size.height} large text',(tester)async{
    tester.view.physicalSize=size;tester.view.devicePixelRatio=1;tester.platformDispatcher.textScaleFactorTestValue=2;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(preview.buildApp(individualPreview:individual));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull,reason:'Overview must support 200% text');
   });
  }
 }
}

