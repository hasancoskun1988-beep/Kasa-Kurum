import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GlobalFinancialTrackerApp());
}

class GlobalFinancialTrackerApp extends StatefulWidget {
  const GlobalFinancialTrackerApp({super.key});

  @override
  State<GlobalFinancialTrackerApp> createState() => _GlobalFinancialTrackerAppState();
}

class _GlobalFinancialTrackerAppState extends State<GlobalFinancialTrackerApp> {
  String _dil = 'Türkçe';
  String _paraBirimi = '₺';

  void dilDegistir(String yeniDil) => setState(() => _dil = yeniDil);
  void paraBirimiDegistir(String yeniBirim) => setState(() => _paraBirimi = yeniBirim);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Global Financial Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
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

  Gider({
    required this.id,
    required this.aciklama,
    required this.tutar,
    required this.tarih,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'aciklama': aciklama,
        'tutar': tutar,
        'tarih': tarih,
      };

  factory Gider.fromJson(Map<String, dynamic> json) => Gider(
        id: json['id']?.toString() ?? '',
        aciklama: json['aciklama']?.toString() ?? '',
        tutar: (json['tutar'] as num?)?.toDouble() ?? 0.0,
        tarih: json['tarih']?.toString() ?? '',
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

class _AnaTakipEkraniState extends State<AnaTakipEkrani>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tab;
  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;
  List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};

  final List<String> _diller = [
    'Türkçe', 'English', 'Deutsch', 'Français', 'Español', 'العربية',
    'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'
  ];

  final List> _paraBirimleri = [
    {'sembol': '₺', 'ad': 'TRY - Türk Lirası (₺)'},
    {'sembol': '\$', 'ad': 'USD - ABD Doları (\$)'},
    {'sembol': '€', 'ad': 'EUR - Euro (€)'},
    {'sembol': '£', 'ad': 'GBP - İngiliz Sterlini (£)'},
    {'sembol': '₼', 'ad': 'AZN - Azerbaycan Manatı (₼)'},
    {'sembol': 'CHF', 'ad': 'CHF - İsviçre Frangı (CHF)'},
    {'sembol': '¥', 'ad': 'JPY/CNY - Yen / Yuan (¥)'},
    {'sembol': '₽', 'ad': 'RUB - Rus Rublesi (₽)'},
    {'sembol': '﷼', 'ad': 'SAR - Suudi Riyali (﷼)'},
    {'sembol': 'د.إ', 'ad': 'AED - BAE Dirhemi (د.إ)'},
    {'sembol': 'د.ك', 'ad': 'KWD - Kuveyt Dinarı (د.ك)'},
    {'sembol': 'ر.ق', 'ad': 'QAR - Katar Riyali (ر.ق)'},
    {'sembol': '₹', 'ad': 'INR - Hindistan Rupisi (₹)'},
    {'sembol': '₩', 'ad': 'KRW - Güney Kore Wonu (₩)'},
    {'sembol': 'C\$', 'ad': 'CAD - Kanada Doları (C\$)'},
    {'sembol': 'A\$', 'ad': 'AUD - Avustralya Doları (A\$)'},
    {'sembol': 'R\$', 'ad': 'BRL - Brezilya Reali (R\$)'},
    {'sembol': 'kr', 'ad': 'SEK/NOK - İsveç/Norveç Kronu (kr)'},
    {'sembol': 'zł', 'ad': 'PLN - Polonya Zlotisi (zł)'},
    {'sembol': '₴', 'ad': 'UAH - Ukrayna Grivnası (₴)'},
    {'sembol': '₸', 'ad': 'KZT - Kazakistan Tengesi (₸)'},
    {'sembol': 'с', 'ad': 'KGS - Kırgızistan Somu (с)'},
    {'sembol': 'soʻm', 'ad': 'UZS - Özbekistan Somu (soʻm)'},
    {'sembol': '₾', 'ad': 'GEL - Gürcistan Larisi (₾)'},
  void _personelEklePenceresi() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addPerson']!),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: t['fullName']!)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  String ad = ctrl.text.trim();
                  if (!_personeller.contains(ad)) _personeller.add(ad);
                  _aktifOdemeler[ad] = _varsayilanAidat;
                });
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

  void _giderEklePenceresi() {
    final aciklamaCtrl = TextEditingController();
    final tutarCtrl = TextEditingController();
    final tarihCtrl = TextEditingController(
      text: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
    );
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addExpense']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aciklamaCtrl, decoration: InputDecoration(labelText: t['desc']!)),
            TextField(
              controller: tutarCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: '${t['amount']!} (Örn: 500,50 veya 500.200,50)'),
            ),
            TextField(controller: tarihCtrl, decoration: InputDecoration(labelText: t['date']!)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              if (aciklamaCtrl.text.trim().isNotEmpty && tutarCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _aktifGiderler.add(Gider(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    aciklama: aciklamaCtrl.text.trim(),
                    tutar: _metniSayiyaCevir(tutarCtrl.text),
                    tarih: tarihCtrl.text.trim(),
                  ));
                });
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

  void _odemeDuzenlePenceresi(String isim) {
    final ctrl = TextEditingController(text: (_aktifOdemeler[isim] ?? _varsayilanAidat).toString());
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$isim - ${t['editPayment']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '${t['amount']!} (Örn: 500,50)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _aktifOdemeler[isim] = _metniSayiyaCevir(ctrl.text);
              });
              _verileriKaydet();
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  void _ayarlarPenceresi() {
    final aidatCtrl = TextEditingController(text: _varsayilanAidat.toString());
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['settings']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t['defaultFee']!),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              controller: aidatCtrl,
              decoration: const InputDecoration(hintText: "Örn: 500,50"),
            ),
            const SizedBox(height: 16),
            Text(t['currency']!),
            DropdownButton<String>(
              value: widget.paraBirimi,
              isExpanded: true,
              items: _paraBirimleri
                  .map((pb) => DropdownMenuItem<String>(value: pb['sembol'], child: Text(pb['ad']!)))
                  .toList(),
              onChanged: (yeni) {
                if (yeni != null) {
                  widget.onParaBirimiDegistir(yeni);
                  _verileriKaydet();
                  Navigator.pop(c);
                }
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                _varsayilanAidat = _metniSayiyaCevir(aidatCtrl.text);
              });
              _verileriKaydet(bildirimGoster: true);
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  void _raporPenceresiAc() {
    final pb = widget.paraBirimi;
    final devir = _devirHesapla();
    final gelir = _toplamGelir;
    final gider = _toplamGider;
    final net = devir + gelir - gider;
    String raporMetni = "--- $_yil ${_aylar[_ay]} ${t['report']} ---\n"
        "${t['devir']} $pb${devir.toStringAsFixed(2)}\n"
        "${t['gelir']} $pb${gelir.toStringAsFixed(2)}\n"
        "${t['gider']} -$pb${gider.toStringAsFixed(2)}\n"
        "${t['net']} $pb${net.toStringAsFixed(2)}\n";
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['report']!),
        content: SingleChildScrollView(child: Text(raporMetni)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: raporMetni));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['copiedMsg']!)));
            },
            child: Text(t['copyText']!),
          ),
          ElevatedButton(onPressed: () => Navigator.pop(c), child: Text(t['ok']!)),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final devir = _devirHesapla(), gelir = _toplamGelir, gider = _toplamGider, net = devir + gelir - gider, pb = widget.paraBirimi;
    return Scaffold(
      appBar: AppBar(
        title: Text('${t['title']!} ($_yil)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.description, color: Colors.red, size: 22), tooltip: t['report'], onPressed: _raporPenceresiAc),
          const SizedBox(width: 8),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.save, color: Colors.indigo, size: 22), tooltip: t['save'], onPressed: () => _verileriKaydet(bildirimGoster: true)),
          const SizedBox(width: 8),
          IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.settings, size: 22), tooltip: t['settings'], onPressed: _ayarlarPenceresi),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: widget.seciliDil,
            underline: const SizedBox(),
            iconSize: 18,
            items: _diller.map((dil) => DropdownMenuItem<String>(value: dil, child: Text(dil, style: const TextStyle(fontSize: 11)))).toList(),
            onChanged: (yeni) {
              if (yeni != null) {
                widget.onDilDegistir(yeni);
                Future.delayed(Duration.zero, () => _verileriKaydet());
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                DropdownButton<int>(
                  value: _yil,
                  items: _yillar.map((y) => DropdownMenuItem<int>(value: y, child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _yil = v);
                      _verileriKaydet();
                    }
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(12, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ChoiceChip(
                          label: Text(_aylar[i]),
                          selected: _ay == i,
                          onSelected: (_) {
                            setState(() => _ay = i);
                            _verileriKaydet();
                          },
                        ),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(10),
            color: Colors.indigo.shade800,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['devir']!, style: const TextStyle(color: Colors.amberAccent)), Text('$pb${devir.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['gelir']!, style: const TextStyle(color: Colors.greenAccent)), Text('$pb${gelir.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['gider']!, style: const TextStyle(color: Colors.redAccent)), Text('-$pb${gider.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                  const Divider(color: Colors.white24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t['net']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('$pb${net.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
                ],
              ),
            ),
          ),
          TabBar(controller: _tab, tabs: [Tab(text: t['tab1']!), Tab(text: t['tab2']!)]),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                Column(
                  children: [
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _odemeDuzenlePenceresi(isim)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () { setState(() { _personeller.removeAt(index); _aktifOdemeler.remove(isim); }); _verileriKaydet(); }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white), onPressed: _giderEklePenceresi, icon: const Icon(Icons.add), label: Text(t['addExpense']!))),
                    Expanded(
                      child: _aktifGiderler.isEmpty
                          ? Center(child: Text(t['noExpense']!, style: const TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              itemCount: _aktifGiderler.length,
                              itemBuilder: (_, index) {
                                Gider g = _aktifGiderler[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: ListTile(
                                    title: Text(g.aciklama),
                                    subtitle: Text(g.tarih, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('-$pb${g.tutar.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() => _aktifGiderler.removeAt(index)); _verileriKaydet(); }),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
