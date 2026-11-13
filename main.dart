import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, dynamic> D;
late SharedPreferences sp;
final FlutterTts tts = FlutterTts();
Set<String> known = {}, fav = {}, wrong = {};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  D = jsonDecode(await rootBundle.loadString('assets/data.json'));
  sp = await SharedPreferences.getInstance();
  known = (sp.getStringList('known') ?? []).toSet();
  fav = (sp.getStringList('fav') ?? []).toSet();
  wrong = (sp.getStringList('wrong') ?? []).toSet();
  await tts.setLanguage('en-US');
  await tts.setSpeechRate(0.45);
  runApp(const App());
}

void save() {
  sp.setStringList('known', known.toList());
  sp.setStringList('fav', fav.toList());
  sp.setStringList('wrong', wrong.toList());
}

void speak(String t) {
  tts.stop();
  tts.speak(t.replaceAll(' / ', ', ').split('→').first.replaceAll('"', ''));
}

List<Map<String, dynamic>> L(dynamic x) =>
    (x as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
List<Map<String, dynamic>> allWords() => L(D['all'] ?? []);
String key(Map w) => (w['e'] as String).toLowerCase();

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'تعلّم الإنجليزية',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF2F6FED)),
        darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF2F6FED)),
        builder: (ctx, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeS();
}

class _HomeS extends State<Home> {
  @override
  Widget build(BuildContext c) {
    final g = (D['groups'] ?? {}) as Map<String, dynamic>;
    final all = allWords();
    Widget tile(String ic, String n, String sub, Widget page) => Card(
          child: InkWell(
            onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => page))
                .then((_) => setState(() {})),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(ic, style: const TextStyle(fontSize: 28)),
                Text(n, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: Theme.of(c).textTheme.bodySmall),
              ]),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('تعلّم الإنجليزية')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        TextField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'ابحث عن كلمة (إنجليزي أو عربي)',
              border: OutlineInputBorder()),
          onSubmitted: (q) {
            final s = q.trim().toLowerCase();
            if (s.isEmpty) return;
            final r = all
                .where((w) => key(w).contains(s) || (w['a'] as String).contains(q.trim()))
                .take(80)
                .toList();
            Navigator.push(c, MaterialPageRoute(builder: (_) => WordList('نتائج: $q', r)))
                .then((_) => setState(() {}));
          },
        ),
        const SizedBox(height: 12),
        Text('✅ حفظت ${known.length} من ${all.length} كلمة'),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: all.isEmpty ? 0 : known.length / all.length),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            tile('📚', 'أهم الكلمات', 'من A إلى Z', const Alpha()),
            tile('📖', 'القواعد', '${(D['gr'] as List? ?? []).length} درس', const Grammar()),
            tile('🏃', 'الأفعال', '${(g['verbs'] as List? ?? []).length}',
                WordList('أهم الأفعال', L(g['verbs'] ?? []))),
            tile('🏷️', 'الأسماء', '${(g['nouns'] as List? ?? []).length}',
                WordList('أهم الأسماء', L(g['nouns'] ?? []))),
            tile('🎨', 'الصفات', '${(g['adjs'] as List? ?? []).length}',
                WordList('أهم الصفات', L(g['adjs'] ?? []))),
            tile('⏱️', 'الظروف', '${(g['advs'] as List? ?? []).length}',
                WordList('أهم الظروف', L(g['advs'] ?? []))),
            tile('🧩', 'كلمات متنوعة', '${(g['topics'] as Map? ?? {}).length} موضوع', const Topics()),
            tile('🔗', 'Phrasal Verbs', '${(g['pv'] as List? ?? []).length}',
                WordList('Phrasal Verbs', L(g['pv'] ?? []))),
            tile('🧷', 'كلمات الربط', '${(g['con'] as List? ?? []).length}',
                WordList('كلمات الربط', L(g['con'] ?? []))),
            tile('📍', 'حروف الجر', '${(g['prep'] as List? ?? []).length}',
                WordList('حروف الجر', L(g['prep'] ?? []))),
            tile('🔁', 'الأفعال الشاذة', '${(g['irr'] as List? ?? []).length}',
                WordList('الأفعال الشاذة', L(g['irr'] ?? []), sort: false)),
            tile('❤️', 'المفضلة', '${fav.length}',
                WordList('المفضلة', all.where((w) => fav.contains(key(w))).toList())),
            tile('🛠️', 'مراجعتي', '${wrong.length}',
                WordList('كلمات أخطأت فيها', all.where((w) => wrong.contains(key(w))).toList())),
            tile('📝', 'اختبار', 'حسب المستوى', const QuizLevels()),
          ],
        ),
      ]),
    );
  }
}

class WordList extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> words;
  final bool sort;
  const WordList(this.title, this.words, {this.sort = true, super.key});
  @override
  State<WordList> createState() => _WLS();
}

class _WLS extends State<WordList> {
  late List<Map<String, dynamic>> ws;
  @override
  void initState() {
    super.initState();
    ws = List.of(widget.words);
    if (widget.sort) {
      ws.sort((a, b) {
        final c = (a['l'] as int? ?? 1).compareTo(b['l'] as int? ?? 1);
        return c != 0 ? c : widget.words.indexOf(a).compareTo(widget.words.indexOf(b));
      });
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ws.isEmpty
            ? const Center(child: Text('مفيش كلمات هنا لسه'))
            : ListView.builder(
                itemCount: ws.length,
                itemBuilder: (_, i) {
                  final w = ws[i];
                  final k = key(w);
                  return Opacity(
                    opacity: known.contains(k) ? 0.55 : 1,
                    child: ListTile(
                      onTap: () => speak(w['e'] as String),
                      title: Text(w['e'] as String,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text('${w['a']}   ${'⭐' * (w['l'] as int? ?? 1)}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: Icon(fav.contains(k) ? Icons.favorite : Icons.favorite_border),
                          onPressed: () => setState(() {
                            fav.contains(k) ? fav.remove(k) : fav.add(k);
                            save();
                          }),
                        ),
                        IconButton(
                          icon: Icon(known.contains(k)
                              ? Icons.check_circle
                              : Icons.check_circle_outline),
                          onPressed: () => setState(() {
                            known.contains(k) ? known.remove(k) : known.add(k);
                            save();
                          }),
                        ),
                      ]),
                    ),
                  );
                },
              ),
      );
}

class Alpha extends StatelessWidget {
  const Alpha({super.key});
  @override
  Widget build(BuildContext c) {
    final m = (D['groups']?['letters'] ?? {}) as Map<String, dynamic>;
    final ks = m.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('أهم الكلمات')),
      body: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(12),
        children: [
          for (final k in ks)
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                    c, MaterialPageRoute(builder: (_) => WordList('حرف $k', L(m[k] ?? [])))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(k, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('${(m[k] as List? ?? []).length}', style: Theme.of(c).textTheme.bodySmall),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class Topics extends StatelessWidget {
  const Topics({super.key});
  @override
  Widget build(BuildContext c) {
    final m = (D['groups']?['topics'] ?? {}) as Map<String, dynamic>;
    final icons = (D['icons'] ?? {}) as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(title: const Text('كلمات متنوعة')),
      body: ListView(children: [
        for (final k in m.keys)
          ListTile(
            leading: Text('${icons[k] ?? '📌'}', style: const TextStyle(fontSize: 24)),
            title: Text(k),
            subtitle: Text('${(m[k] as List? ?? []).length} كلمة'),
            onTap: () => Navigator.push(
                c, MaterialPageRoute(builder: (_) => WordList(k, L(m[k] ?? [])))),
          ),
      ]),
    );
  }
}

class Grammar extends StatelessWidget {
  const Grammar({super.key});
  @override
  Widget build(BuildContext c) {
    final gr = (D['gr'] as List? ?? []);
    return Scaffold(
      appBar: AppBar(title: const Text('القواعد')),
      body: ListView.builder(
        itemCount: gr.length,
        itemBuilder: (_, i) => ListTile(
          title: Text('${i + 1}. ${gr[i]['t']}'),
          onTap: () => Navigator.push(c,
              MaterialPageRoute(builder: (_) => Lesson(Map<String, dynamic>.from(gr[i] as Map)))),
        ),
      ),
    );
  }
}

class Lesson extends StatelessWidget {
  final Map<String, dynamic> l;
  const Lesson(this.l, {super.key});
  @override
  Widget build(BuildContext c) {
    final b = (l['b'] as List? ?? []).cast<String>();
    final ex = (D['ex'] ?? {}) as Map<String, dynamic>;
    String? k;
    for (final e in ex.keys) {
      if ((l['t'] as String? ?? '').contains(e)) {
        k = e;
        break;
      }
    }
    return Scaffold(
      appBar: AppBar(title: Text(l['t'] as String? ?? '', style: const TextStyle(fontSize: 15))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (final s in b)
          s.startsWith('EN:')
              ? Card(
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.volume_up),
                    title: Text(s.substring(3), textDirection: TextDirection.ltr),
                    onTap: () => speak(s.substring(3)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(s, style: const TextStyle(fontSize: 16, height: 1.7)),
                ),
        if (k != null)
          FilledButton.icon(
            icon: const Icon(Icons.quiz),
            label: const Text('جرّب تمرين على الدرس'),
            onPressed: () => Navigator.push(
                c,
                MaterialPageRoute(
                    builder: (_) => Exercise(l['t'] as String, ex[k] as List? ?? []))),
          ),
      ]),
    );
  }
}

class Exercise extends StatefulWidget {
  final String title;
  final List qs;
  final bool speakQ;
  final TextDirection optDir;
  final void Function(int, bool)? onAnswer;
  const Exercise(this.title, this.qs,
      {this.speakQ = false, this.optDir = TextDirection.ltr, this.onAnswer, super.key});
  @override
  State<Exercise> createState() => _ExS();
}

class _ExS extends State<Exercise> {
  int i = 0, score = 0;
  int? picked;
  @override
  Widget build(BuildContext c) {
    if (i >= widget.qs.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('النتيجة')),
        body: Center(
            child: Text('نتيجتك: $score من ${widget.qs.length}',
                style: const TextStyle(fontSize: 26))),
      );
    }
    final q = widget.qs[i] as List;
    final opts = (q[1] as List? ?? []).cast<String>();
    final ans = q[2] as int;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(fontSize: 14))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('${i + 1} / ${widget.qs.length}', textAlign: TextAlign.center),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(q[0] as String,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        for (var j = 0; j < opts.length; j++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: FilledButton.tonal(
              style: picked == null
                  ? null
                  : FilledButton.styleFrom(
                      backgroundColor: j == ans
                          ? Colors.green.shade300
                          : (j == picked ? Colors.red.shade300 : null)),
              onPressed: () {
                if (picked != null) return;
                setState(() {
                  picked = j;
                  if (j == ans) score++;
                });
                widget.onAnswer?.call(i, j == ans);
                if (widget.speakQ) speak(q[0] as String);
              },
              child: Text(opts[j], textDirection: widget.optDir),
            ),
          ),
        if (picked != null)
          FilledButton(
              onPressed: () => setState(() {
                    i++;
                    picked = null;
                  }),
              child: const Text('التالي')),
      ]),
    );
  }
}

class QuizLevels extends StatelessWidget {
  const QuizLevels({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('اختبار')),
        body: ListView(children: [
          for (final e in const [
            ['⭐ أساسي', 1],
            ['⭐⭐ متوسط', 2],
            ['⭐⭐⭐ متقدم', 3],
            ['🎲 مختلط', 0],
          ])
            ListTile(
              title: Text(e[0] as String, style: const TextStyle(fontSize: 18)),
              onTap: () => Navigator.push(
                  c, MaterialPageRoute(builder: (_) => quizPage(e[1] as int))),
            ),
        ]),
      );
}

Widget quizPage(int lv) {
  final r = Random();
  var pool = allWords();
  if (lv > 0) pool = pool.where((w) => w['l'] == lv).toList();
  final words = (List.of(pool)..shuffle(r)).take(10).toList();
  final qs = <List>[];
  for (final w in words) {
    final others = (List.of(pool)..shuffle(r))
        .where((x) => x['a'] != w['a'])
        .take(3)
        .map((x) => x['a'] as String)
        .toList();
    final opts = <String>[w['a'] as String, ...others]..shuffle(r);
    qs.add([w['e'], opts, opts.indexOf(w['a'] as String)]);
  }
  return Exercise('اختبار', qs, speakQ: true, optDir: TextDirection.rtl, onAnswer: (i, ok) {
    final k = key(words[i]);
    ok ? wrong.remove(k) : wrong.add(k);
    save();
  });
}
