import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const ZunoApp());
}

const ink = Color(0xFF090B12);
const panel = Color(0xFF151925);
const gold = Color(0xFFFFC857);
const muted = Color(0xFF9BA3B4);

class ZunoApp extends StatelessWidget {
  const ZunoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ZUNO',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: gold, surface: panel),
      appBarTheme: const AppBarTheme(backgroundColor: ink, elevation: 0),
    ),
    home: const MainShell(),
  );
}

class Clip {
  final String creator, caption, tag;
  final IconData art;
  final Color color;
  final int likes;
  const Clip(this.creator,this.caption,this.tag,this.art,this.color,this.likes);
}
const clips = [
 Clip('Mariam • القاهرة','لما تقول هخرج خمس دقايق وترجع بعد 3 ساعات 😂','كوميديا',Icons.face_retouching_natural,Color(0xFF563A75),12400),
 Clip('Ahmed • الإسكندرية','لقطة من قلب البحر وقت الغروب 🌊','سفر',Icons.waves,Color(0xFF174D70),8200),
 Clip('Nour • الجيزة','3 أفكار بسيطة تخلي يومك أحسن ✨','لايف ستايل',Icons.auto_awesome,Color(0xFF72502A),5100),
];

class MainShell extends StatefulWidget {
 const MainShell({super.key});
 @override State<MainShell> createState()=>_MainShellState();
}
class _MainShellState extends State<MainShell>{
 int tab=0;
 final pages=const [FeedPage(),DiscoverPage(),UploadPage(),InboxPage(),ProfilePage()];
 @override Widget build(BuildContext context)=>Scaffold(
 body: SafeArea(child:pages[tab]),
 bottomNavigationBar: NavigationBar(
  backgroundColor: ink, indicatorColor: gold.withOpacity(.16),
  selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),
  destinations:const [
   NavigationDestination(icon:Icon(Icons.play_circle_outline),selectedIcon:Icon(Icons.play_circle_fill,color:gold),label:'الرئيسية'),
   NavigationDestination(icon:Icon(Icons.search),label:'اكتشف'),
   NavigationDestination(icon:Icon(Icons.add_box_outlined),label:'نشر'),
   NavigationDestination(icon:Icon(Icons.chat_bubble_outline),label:'الرسائل'),
   NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي'),
  ]),
 );
}

class FeedPage extends StatefulWidget {const FeedPage({super.key});@override State<FeedPage> createState()=>_FeedPageState();}
class _FeedPageState extends State<FeedPage>{
 int index=0; bool liked=false;
 @override Widget build(BuildContext context)=>Stack(children:[
  PageView.builder(scrollDirection:Axis.vertical,itemCount:clips.length,itemBuilder:(c,i){
   final v=clips[i];return Container(
    decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[v.color,ink])),
    child:Stack(children:[
     Center(child:Icon(v.art,size:190,color:Colors.white.withOpacity(.13))),
     Positioned(top:12,left:0,right:0,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      Text('متابعة',style:TextStyle(color:muted,fontSize:16)),
      const SizedBox(width:24),const Text('لك',style:TextStyle(color:gold,fontSize:18,fontWeight:FontWeight.bold)),
     ])),
     Positioned(right:14,bottom:95,child:Column(children:[
      const CircleAvatar(radius:25,backgroundColor:gold,child:Icon(Icons.person,color:ink)),
      const SizedBox(height:18),IconButton(onPressed:()=>setState(()=>liked=!liked),icon:Icon(liked?Icons.favorite:Icons.favorite_border,color:liked?Colors.red:Colors.white,size:32)),
      Text('${(v.likes/1000).toStringAsFixed(1)}K'),
      const SizedBox(height:18),const Icon(Icons.chat_bubble_outline,size:30),const Text('238'),
      const SizedBox(height:18),const Icon(Icons.share_outlined,size:30),const Text('مشاركة'),
      const SizedBox(height:18),const Icon(Icons.more_horiz,size:30),
     ])),
     Positioned(left:16,right:85,bottom:30,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('@${v.creator}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      const SizedBox(height:8),Text(v.caption,style:const TextStyle(fontSize:15)),
      const SizedBox(height:10),Row(children:[const Icon(Icons.music_note,size:16),const SizedBox(width:5),Text('صوت ZUNO الأصلي • ${v.tag}')]),
     ])),
    ]));
  }),
  Positioned(top:10,right:14,child:Text('ZUNO',style:TextStyle(color:gold,fontWeight:FontWeight.w900,fontSize:23,letterSpacing:2))),
 );
}

class DiscoverPage extends StatelessWidget{const DiscoverPage({super.key});@override Widget build(BuildContext c)=>Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Text('اكتشف',style:TextStyle(fontSize:28,fontWeight:FontWeight.bold)),const SizedBox(height:16),
 const TextField(decoration:InputDecoration(hintText:'ابحث عن فيديو أو مبدع',prefixIcon:Icon(Icons.search),filled:true,fillColor:panel,border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(16)),borderSide:BorderSide.none))),
 const SizedBox(height:22),const Text('الترندات الآن',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),
 ...['#ضحك_من_القلب','#يوميات_مصرية','#ZUNO_Challenge','#سفر_ومغامرات'].map((x)=>ListTile(leading:const Icon(Icons.trending_up,color:gold),title:Text(x),subtitle:const Text('محتوى متداول على ZUNO'))),
 ]));}

class UploadPage extends StatelessWidget{const UploadPage({super.key});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
 const Icon(Icons.video_call_outlined,size:85,color:gold),const SizedBox(height:18),const Text('شارك لحظتك',style:TextStyle(fontSize:26,fontWeight:FontWeight.bold)),const SizedBox(height:10),const Text('ارفع فيديو قصير وخلي العالم يشوف إبداعك',textAlign:TextAlign.center,style:TextStyle(color:muted)),
 const SizedBox(height:24),FilledButton.icon(onPressed:()=>showDialog(context:c,builder:(_)=>AlertDialog(title:const Text('رفع الفيديو'),content:const Text('واجهة تجريبية: ربط اختيار الفيديو والتخزين السحابي مطلوب في مرحلة Backend.'),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('تمام'))])),icon:const Icon(Icons.add),label:const Text('اختيار فيديو')),
 ])));}

class InboxPage extends StatelessWidget{const InboxPage({super.key});@override Widget build(BuildContext c)=>const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.mark_chat_unread_outlined,size:70,color:gold),SizedBox(height:12),Text('رسائلك هتظهر هنا'),Text('قريبًا في النسخة المتصلة بالخادم',style:TextStyle(color:muted))]));}
class ProfilePage extends StatelessWidget{const ProfilePage({super.key});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(20),children:[
 const CircleAvatar(radius:44,backgroundColor:panel,child:Icon(Icons.person,size:45,color:gold)),const SizedBox(height:12),const Center(child:Text('مستخدم ZUNO',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold))),const Center(child:Text('@zuno_user',style:TextStyle(color:muted))),const SizedBox(height:22),
 const Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[_Stat('0','متابع'),_Stat('0','متابَعون'),_Stat('0','إعجاب')]),const SizedBox(height:22),
 const Card(color:panel,child:ListTile(leading:Icon(Icons.account_circle,color:gold),title:Text('تعديل الملف الشخصي'),trailing:Icon(Icons.chevron_left))),
 const Card(color:panel,child:ListTile(leading:Icon(Icons.wallet,color:gold),title:Text('المحفظة'),subtitle:Text('الأرصدة والأرباح تظهر بعد تفعيل النظام'))),
 const Card(color:panel,child:ListTile(leading:Icon(Icons.settings,color:gold),title:Text('الإعدادات والخصوصية'))),
 ]);}
class _Stat extends StatelessWidget{final String n,l;const _Stat(this.n,this.l);@override Widget build(BuildContext c)=>Column(children:[Text(n,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),Text(l,style:const TextStyle(color:muted))]);}
