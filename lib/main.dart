import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KurumKasaApp());
}

class KurumKasaApp extends StatefulWidget {
  const KurumKasaApp({super.key});

  @override
  State<KurumKasaApp> createState() => _KurumKasaAppState();
}

class _KurumKasaAppState extends State<KurumKasaApp> {
  String _dil = 'Türkçe';
  String _paraBirimi = '₺';

  void dilDegistir(String yeniDil) => setState(() => _dil = yeniDil);
  void paraBirimiDegistir(String yeniBirim) => setState(() => _paraBirimi = yeniBirim);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
      home: AnaTakipEkrani(
        seciliDil: _dil,
        paraBirimi: _paraBirimi,
        onDilDegistir: dilDegistir,
        onParaBirimiDegistir: paraBirimiDegistir,
      ),
    );
  }
}

class Gider {
  final String id, aciklama, tarih;
  final double tutar;

  Gider({required this.id, required this.aciklama, required this.tutar, required this.tarih});

  Map<String, dynamic> toJson() => {'id': id, 'aciklama': aciklama, 'tutar': tutar, 'tarih': tarih};

  factory Gider.fromJson(Map<String, dynamic> json) => Gider(
        id: json['id'] ?? '',
        aciklama: json['aciklama'] ?? '',
        tutar: (json['tutar'] as num?)?.toDouble() ?? 0.0,
        tarih: json['tarih'] ?? '',
      );
}

class AnaTakipEkrani extends StatefulWidget {
  final String seciliDil, paraBirimi;
  final Function(String) onDilDegistir, onParaBirimiDegistir;

  const AnaTakipEkrani({
    super.key,
    required this.seciliDil,
    required this.paraBirimi,
    required this.onDilDegistir,
    required this.onParaBirimiDegistir,
  });

  @override
  State<AnaTakipEkrani> createState() => _AnaTakipEkraniState();
}

class _AnaTakipEkraniState extends State<AnaTakipEkrani> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tab;
  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  final List<String> _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;
  List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};
  final List<String> _diller = ['Türkçe', 'English', 'Deutsch', 'Français', 'Español', 'العربية', 'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'];

  Map<String, String> get t {
    final sozlukler = {
      'English': {
        'title': '2006-2050 Financial Tracking', 'devir': 'Previous Balance:', 'gelir': 'Personnel Income:',
        'gider': 'Expenses:', 'net': 'Next Month Balance:', 'tab1': 'Personnel', 'tab2': 'Expenses',
        'addPerson': '+ Add Personnel', 'addExpense': '+ Add Expense', 'delete': 'Delete', 'save': 'Save',
        'cancel': 'Cancel', 'settings': 'Settings', 'defaultFee': 'Default Amount:', 'currency': 'Currency Symbol:',
        'editPayment': 'Enter Payment Amount', 'paid': 'Paid:', 'waiting': 'Waiting for payment',
        'savedMsg': 'All data saved to device!', 'report': 'Monthly Report',
      },
      'Türkçe': {
        'title': '2006-2050 Kasa Takip', 'devir': 'Geçen Aydan Devir:', 'gelir': 'Personel Geliri:',
        'gider': 'Aylık Gider:', 'net': 'Sonraki Aya Devir:', 'tab1': 'Personel Listesi', 'tab2': 'Giderler',
        'addPerson': '+ Yeni Personel Ekle', 'addExpense': '+ Gider Ekle (Tarihli)', 'delete': 'Sil', 'save': 'Kaydet',
        'cancel': 'İptal', 'settings': 'Ayarlar', 'defaultFee': 'Varsayılan Tutar:', 'currency': 'Para Birimi:',
        'editPayment': 'Ödeme Tutarını Girin', 'paid': 'Ödenen:', 'waiting': 'Ödeme bekleniyor',
        'savedMsg': 'Tüm veriler telefon hafızasına kaydedildi!', 'report': 'Aylık Rapor / Çıktı',
      }
    };
    return sozlukler[widget.seciliDil] ?? sozlukler['English']!;
  }

  File get _kayitDosyasi => File('${Directory.systemTemp.parent.path}/kurum_kasa_verileri.json');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tab = TabController(length: 2, vsync: this);
    _verileriYukle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _verileriKaydet();
    }
  }

  Future<void> _verileriYukle() async {
    try {
      if (await _kayitDosyasi.exists()) {
        final veri = jsonDecode(await _kayitDosyasi.readAsString()) as Map<String, dynamic>;
        if (veri['personeller'] != null) _personeller = List<String>.from(veri['personeller']);
        if (veri['varsayilanAidat'] != null) _varsayilanAidat = (veri['varsayilanAidat'] as num).toDouble();
        if (veri['odemeler'] != null) {
          _odemeler.clear();
          (veri['odemeler'] as Map<String, dynamic>).forEach((k, v) {
            _odemeler[k] = (v as Map<String, dynamic>).map((p, a) => MapEntry(p, (a as num).toDouble()));
          });
        }
        if (veri['giderler'] != null) {
          _giderler.clear();
          (veri['giderler'] as Map<String, dynamic>).forEach((k, l) {
            _giderler[k] = (l as List).map((i) => Gider.fromJson(i as Map<String, dynamic>)).toList();
          });
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _verileriKaydet({bool bildirimGoster = false}) async {
    try {
      final giderlerMap = <String, dynamic>{};
      _giderler.forEach((k, l) => giderlerMap[k] = l.map((g) => g.toJson()).toList());
      await _kayitDosyasi.writeAsString(jsonEncode({
        'personeller': _personeller, 'varsayilanAidat': _varsayilanAidat, 'odemeler': _odemeler, 'giderler': giderlerMap,
      }));
      if (bildirimGoster && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['savedMsg']!), backgroundColor: Colors.green.shade700));
      }
    } catch (_) {}
  }

String get _ayKey => '$_yil-$_ay';
  Map<String, double> get _aktifOdemeler => _odemeler.putIfAbsent(_ayKey, () => {});
  List<Gider> get _aktifGiderler => _giderler.putIfAbsent(_ayKey, () => []);
  double get _toplamGelir => _aktifOdemeler.values.fold(0.0, (s, v) => s + v);
  double get _toplamGider => _aktifGiderler.fold(0.0, (s, g) => s + g.tutar);

  double _devirHesapla() {
    double d = 0.0;
    for (int y = 2006; y <= _yil; y++) {
      int sonAy = (y == _yil) ? _ay - 1 : 11;
      for (int a = 0; a <= sonAy; a++) {
        String key = '$y-$a';
        d += (_odemeler[key] ?? {}).values.fold(0.0, (s, v) => s + v) - (_giderler[key] ?? []).fold(0.0, (s, x) => s + x.tutar);
      }
    }
    return d;
  }

  void _raporPenceresiAc() {
    final devir = _devirHesapla(), gelir = _toplamGelir, gider = _toplamGider, net = devir + gelir - gider, pb = widget.paraBirimi;
    final b = StringBuffer()
      ..writeln('=== ${_aylar[_ay]} $_yil KASA RAPORU ===')
      ..writeln('Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}')
      ..writeln('----------------------------------')
      ..writeln('${t['devir']} $pb${devir.toStringAsFixed(0)}')
      ..writeln('${t['gelir']} +$pb${gelir.toStringAsFixed(0)}')
      ..writeln('${t['gider']} -$pb${gider.toStringAsFixed(0)}')
      ..writeln('${t['net']} $pb${net.toStringAsFixed(0)}')
      ..writeln('----------------------------------\nPERSONEL ODEMELERI:');
    for (final isim in _personeller) {
      final odenen = _aktifOdemeler[isim] ?? 0.0;
      b.writeln('- $isim: ${odenen > 0 ? "$pb${odenen.toStringAsFixed(0)} (Odendi)" : "Bekliyor"}');
    }
    b.writeln('----------------------------------\nAYLIK GIDERLER:');
    if (_aktifGiderler.isEmpty) {
      b.writeln('- Kayitli gider yok.');
    } else {
      for (final g in _aktifGiderler) {
        b.writeln('- [${g.tarih}] ${g.aciklama}: -$pb${g.tutar.toStringAsFixed(0)}');
      }
    }
    final raporMetni = b.toString();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('${_aylar[_ay]} $_yil Raporu'),
        content: SingleChildScrollView(child: SelectableText(raporMetni, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: raporMetni));
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapor kopyalandı!')));
            },
            child: const Text('Metni Kopyala'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dir = Directory('/storage/emulated/0/Download');
                if (await dir.exists()) {
                  await File('${dir.path}/Kasa_Raporu_${_yil}_${_ay + 1}.txt').writeAsString(raporMetni);
                  if (mounted) {
                    Navigator.pop(c);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('İndirilenlere kaydedildi: Kasa_Raporu_${_yil}_${_ay + 1}.txt'), backgroundColor: Colors.green.shade700));
                  }
                }
              } catch (_) {
                Clipboard.setData(ClipboardData(text: raporMetni));
                if (mounted) Navigator.pop(c);
              }
            },
            child: const Text('İndirilenlere Kaydet'),
          ),
        ],
      ),
    );
  }

  void _ayarlarPenceresi() {
    final tutarCtrl = TextEditingController(text: _varsayilanAidat.toString()), birimCtrl = TextEditingController(text: widget.paraBirimi);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['settings']!),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: birimCtrl, decoration: InputDecoration(labelText: t['currency'])),
          TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t['defaultFee'])),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(tutarCtrl.text);
              if (yeniTutar != null && yeniTutar >= 0) setState(() => _varsayilanAidat = yeniTutar);
              if (birimCtrl.text.trim().isNotEmpty) widget.onParaBirimiDegistir(birimCtrl.text.trim());
              _verileriKaydet();
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  void _odemeDuzenlePenceresi(String isim) {
    final ctrl = TextEditingController(text: (_aktifOdemeler[isim] ?? _varsayilanAidat).toString());
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$isim - ${t['editPayment']}'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: '${t['defaultFee']} (${widget.paraBirimi})')),
        actions: [
          TextButton(onPressed: () { setState(() => _aktifOdemeler[isim] = 0.0); _verileriKaydet(); Navigator.pop(c); }, child: Text(t['delete']!, style: const TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () { setState(() => _aktifOdemeler[isim] = double.tryParse(ctrl.text) ?? 0.0); _verileriKaydet(); Navigator.pop(c); }, child: Text(t['save']!)),
        ],
      ),
    );
  }

  void _personelEklePenceresi() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addPerson']!),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Ad Soyad')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(onPressed: () { if (ctrl.text.trim().isNotEmpty) { setState(() => _personeller.add(ctrl.text.trim())); _verileriKaydet(); } Navigator.pop(c); }, child: Text(t['save']!)),
        ],
      ),
    );
  }

  void _giderEklePenceresi() {
    final aciklamaCtrl = TextEditingController(), tutarCtrl = TextEditingController();
    final tarihCtrl = TextEditingController(text: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addExpense']!),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: aciklamaCtrl, decoration: const InputDecoration(labelText: 'Açıklama (Örn: Elektrik)')),
          TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})')),
          TextField(controller: tarihCtrl, decoration: const InputDecoration(labelText: 'Tarih (GG.AA.YYYY)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final tutar = double.tryParse(tutarCtrl.text) ?? 0.0;
              if (aciklamaCtrl.text.trim().isNotEmpty && tutar > 0) {
                setState(() => _aktifGiderler.insert(0, Gider(id: DateTime.now().millisecondsSinceEpoch.toString(), aciklama: aciklamaCtrl.text.trim(), tutar: tutar, tarih: tarihCtrl.text.trim())));
                _verileriKaydet();
              }
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devir = _devirHesapla(), gelir = _toplamGelir, gider = _toplamGider, net = devir + gelir - gider, pb = widget.paraBirimi;
    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']!, style: const TextStyle(fontSize: 12)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.description, color: Colors.red), tooltip: t['report'], onPressed: _raporPenceresiAc),
          IconButton(icon: const Icon(Icons.save, color: Colors.indigo), tooltip: t['save'], onPressed: () => _verileriKaydet(bildirimGoster: true)),
          IconButton(icon: const Icon(Icons.settings), tooltip: t['settings'], onPressed: _ayarlarPenceresi),
          DropdownButton<String>(
            value: widget.seciliDil,
            underline: const SizedBox(),
            items: _diller.map((dil) => DropdownMenuItem(value: dil, child: Text(dil, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (yeni) => widget.onDilDegistir(yeni!),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.indigo.shade50,
            child: Row(children: [
              DropdownButton<int>(value: _yil, items: _yillar.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold)))).toList(), onChanged: (v) => setState(() => _yil = v!)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: List.generate(12, (i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ChoiceChip(label: Text(_aylar[i]), selected: _ay == i, onSelected: (_) => setState(() => _ay = i))))),
                ),
              ),
            ]),
          ),
          Card(
            margin: const EdgeInsets.all(10),
            color: Colors.indigo.shade800,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['devir']!, style: const TextStyle(color: Colors.amberAccent)), Text('$pb${devir.toStringAsFixed(0)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['gelir']!, style: const TextStyle(color: Colors.greenAccent)), Text('$pb${gelir.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['gider']!, style: const TextStyle(color: Colors.redAccent)), Text('-$pb${gider.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                const Divider(color: Colors.white24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['net']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('$pb${net.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
              ]),
            ),
          ),
          TabBar(controller: _tab, tabs: [Tab(text: t['tab1']!), Tab(text: t['tab2']!)]),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                Column(children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(onPressed: _personelEklePenceresi, icon: const Icon(Icons.person_add), label: Text(t['addPerson']!))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _personeller.length,
                      itemBuilder: (_, index) {
                        String isim = _personeller[index];
                        double odenen = _aktifOdemeler[isim] ?? 0.0;
                        bool odedi = odenen > 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: ListTile(
                            leading: IconButton(icon: Icon(odedi ? Icons.check_circle : Icons.radio_button_unchecked, color: odedi ? Colors.green : Colors.grey), onPressed: () => _odemeDuzenlePenceresi(isim)),
                            title: Text(isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(odedi ? '${t['paid']} $pb$odenen' : t['waiting']!),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _odemeDuzenlePenceresi(isim)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () { setState(() { _personeller.removeAt(index); _aktifOdemeler.remove(isim); }); _verileriKaydet(); }),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
                Column(children: [
                  Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white), onPressed: _giderEklePenceresi, icon: const Icon(Icons.add), label: Text(t['addExpense']!))),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _aktifGiderler.length,
                      itemBuilder: (_, index) {
                        Gider g = _aktifGiderler[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: ListTile(
                            title: Text(g.aciklama),
                            subtitle: Text('Tarih: ${g.tarih}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text('-$pb${g.tutar.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() => _aktifGiderler.removeAt(index)); _verileriKaydet(); }),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
