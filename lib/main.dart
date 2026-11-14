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

class _AnaTakipEkraniState extends State<AnaTakipEkrani> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    {'sembol': 'GEL', 'ad': 'GEL - Gürcistan Larisi (₾)'},
    {'sembol': '₪', 'ad': 'ILS - İsrail Şekeli (₪)'},
    {'sembol': 'R', 'ad': 'ZAR - Güney Afrika Randı (R)'},
    {'sembol': '₦', 'ad': 'NGN - Nijerya Nairası (₦)'},
    {'sembol': '฿', 'ad': 'THB - Tayland Bahtı (฿)'},
    {'sembol': 'Rp', 'ad': 'IDR - Endonezya Rupiahı (Rp)'},
    {'sembol': 'RM', 'ad': 'MYR - Malezya Ringgiti (RM)'},
    {'sembol': '₱', 'ad': 'PHP - Filipin Pesosu (₱)'},
    {'sembol': '₫', 'ad': 'VND - Vietnam Dongu (₫)'},
  ];

  List<String> get _aylar {
    final aylarMap = {
      'Türkçe': ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'],
      'English': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      'Deutsch': ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
      'Français': ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'],
      'Español': ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      'العربية': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
      'Русский': ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
      '中文': ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
      '日本語': ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],
      'Português': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
      'Italiano': ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'],
      'हिन्दी': ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'],
    };
    return aylarMap[widget.seciliDil] ?? aylarMap['English']!;
  }

  Map<String, String> get t {
    final sozlukler = {
      'Türkçe': {
        'title': '2006-2050 Kasa Takip', 'devir': 'Geçen Aydan Devir:', 'gelir': 'Personel Geliri:',
        'gider': 'Aylık Gider:', 'net': 'Sonraki Aya Devir:', 'tab1': 'Personel Ekle ve Gelirler', 'tab2': 'Giderler',
        'addPerson': '+ Yeni Personel Ekle', 'addExpense': '+ Gider Ekle (Tarihli)', 'delete': 'Sil', 'save': 'Kaydet',
        'cancel': 'İptal', 'settings': 'Ayarlar', 'defaultFee': 'Varsayılan Tutar:', 'currency': 'Para Birimi Seçin:',
        'editPayment': 'Ödeme Tutarını Girin', 'paid': 'Ödenen:', 'waiting': 'Ödeme bekleniyor',
        'savedMsg': 'Tüm veriler telefon hafızasına kaydedildi!', 'report': 'Aylık Rapor / Çıktı',
        'fullName': 'Ad Soyad', 'desc': 'Açıklama (Örn: Elektrik)', 'amount': 'Tutar', 'date': 'Tarih (GG.AA.YYYY)',
        'copyText': 'Metni Kopyala', 'copiedMsg': 'Rapor kopyalandı!', 'saveDownloads': 'İndirilenlere Kaydet',
        'noExpense': 'Kayıtlı gider yok.',
        'welcomeTitle': 'Kurum Kasa Takip\'e Hoş Geldiniz',
        'welcomeMsg': '2006-2050 yılları arasındaki personel ekle ve gelirler işlemlerinizi, aylık giderlerinizi ve devir bakiyelerinizi tek ekrandan yönetebilir, anında kasa raporu alabilirsiniz.',
        'startBtn': 'Kasayı Aç',
      },
      'English': {
        'title': '2006-2050 Financial Tracking', 'devir': 'Previous Balance:', 'gelir': 'Personnel Income:',
        'gider': 'Expenses:', 'net': 'Next Month Balance:', 'tab1': 'Add Personnel & Income', 'tab2': 'Expenses',
        'addPerson': '+ Add Personnel', 'addExpense': '+ Add Expense', 'delete': 'Delete', 'save': 'Save',
        'cancel': 'Cancel', 'settings': 'Settings', 'defaultFee': 'Default Amount:', 'currency': 'Select Currency:',
        'editPayment': 'Enter Payment Amount', 'paid': 'Paid:', 'waiting': 'Waiting for payment',
        'savedMsg': 'All data saved to device!', 'report': 'Monthly Report',
        'fullName': 'Full Name', 'desc': 'Description (e.g. Electricity)', 'amount': 'Amount', 'date': 'Date (DD.MM.YYYY)',
        'copyText': 'Copy Text', 'copiedMsg': 'Report copied!', 'saveDownloads': 'Save to Downloads',
        'noExpense': 'No recorded expenses.',
        'welcomeTitle': 'Welcome to Financial Tracking',
        'welcomeMsg': 'Easily manage adding personnel & income, monthly expenses, and carried-over balances from 2006 to 2050, and generate instant monthly reports.',
        'startBtn': 'Open Cashbook',
      },
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _karsilamaMesajiGoster());
  }

  void _karsilamaMesajiGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(t['welcomeTitle']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo))),
          ],
        ),
        content: Text(t['welcomeMsg']!, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(c),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(t['startBtn']!),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tab.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _verileriKaydet();
    }
  }

  Future<void> _verileriYukle() async {
    try {
      if (await _kayitDosyasi.exists()) {
        final Map<String, dynamic> veri = jsonDecode(await _kayitDosyasi.readAsString()) as Map<String, dynamic>;
        
        if (veri['personeller'] != null) {
          _personeller = List<String>.from(veri['personeller'] as List);
        }
        if (veri['varsayilanAidat'] != null) {
          _varsayilanAidat = (veri['varsayilanAidat'] as num).toDouble();
        }
        if (veri['odemeler'] != null) {
          _odemeler.clear();
          (veri['odemeler'] as Map<String, dynamic>).forEach((k, v) {
            final Map<String, double> subMap = {};
            (v as Map<String, dynamic>).forEach((p, a) {
              subMap[p] = (a as num).toDouble();
            });
            _odemeler[k] = subMap;
          });
        }
        if (veri['giderler'] != null) {
          _giderler.clear();
          (veri['giderler'] as Map<String, dynamic>).forEach((k, l) {
            final List<Gider> giderListesi = (l as List)
                .map((i) => Gider.fromJson(i as Map<String, dynamic>))
                .toList();
            _giderler[k] = giderListesi;
          });
        }
        setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _verileriKaydet({bool bildirimGoster = false}) async {
    try {
      final Map<String, dynamic> veri = {
        'personeller': _personeller,
        'varsayilanAidat': _varsayilanAidat,
        'odemeler': _odemeler,
        'giderler': _giderler.map((k, l) => MapEntry(k, l.map((g) => g.toJson()).toList())),
      };
      await _kayitDosyasi.writeAsString(jsonEncode(veri));
      if (bildirimGoster && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t['savedMsg']!)));
      }
    } catch (_) {}
  }

  String get _donemKey => '$_yil-$_ay';
  Map<String, double> get _aktifOdemeler => _odemeler.putIfAbsent(_donemKey, () => {});
  List<Gider> get _aktifGiderler => _giderler.putIfAbsent(_donemKey, () => []);

  double get _toplamGelir => _aktifOdemeler.values.fold(0.0, (a, b) => a + b);
  double get _toplamGider => _aktifGiderler.fold(0.0, (a, b) => a + b.tutar);

  double _devirHesapla() {
    double toplamDevir = 0.0;
    int y = 2006, a = 0;
    while (y < _yil || (y == _yil && a < _ay)) {
      String key = '$y-$a';
      double g = (_odemeler[key]?.values.fold(0.0, (t, v) => (t ?? 0.0) + v)) ?? 0.0;
      double gi = (_giderler[key]?.fold(0.0, (t, x) => t + x.tutar)) ?? 0.0;
      toplamDevir += (g - gi);
      a++;
      if (a > 11) { a = 0; y++; }
    }
    return toplamDevir;
  }

  void _personelEklePenceresi() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addPerson']!),
        content: TextField(controller: ctrl, decoration: InputDecoration(labelText: t['fullName']!)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(onPressed: () {
            if (ctrl.text.isNotEmpty) {
              setState(() {
                _personeller.add(ctrl.text.trim());
                _aktifOdemeler[ctrl.text.trim()] = _varsayilanAidat;
              });
              _verileriKaydet();
            }
            Navigator.pop(c);
          }, child: Text(t['save']!)),
        ],
      ),
    );
  }

  void _giderEklePenceresi() {
    final aciklamaCtrl = TextEditingController();
    final tutarCtrl = TextEditingController();
    final tarihCtrl = TextEditingController(text: '${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addExpense']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aciklamaCtrl, decoration: InputDecoration(labelText: t['desc']!)),
            TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t['amount']!)),
            TextField(controller: tarihCtrl, decoration: InputDecoration(labelText: t['date']!)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(onPressed: () {
            if (aciklamaCtrl.text.isNotEmpty && tutarCtrl.text.isNotEmpty) {
              setState(() {
                _aktifGiderler.add(Gider(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  aciklama: aciklamaCtrl.text.trim(),
                  tutar: double.tryParse(tutarCtrl.text.replaceAll(',', '.')) ?? 0.0,
                  tarih: tarihCtrl.text.trim(),
                ));
              });
              _verileriKaydet();
            }
            Navigator.pop(c);
          }, child: Text(t['save']!)),
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
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t['amount']!)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(onPressed: () {
            setState(() {
              _aktifOdemeler[isim] = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
            });
            _verileriKaydet();
            Navigator.pop(c);
          }, child: Text(t['save']!)),
        ],
      ),
    );
  }

  void _ayarlarPenceresi() {
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
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: _varsayilanAidat.toString()),
              onChanged: (v) => _varsayilanAidat = double.tryParse(v) ?? _varsayilanAidat,
            ),
            const SizedBox(height: 16),
            Text(t['currency']!),
            DropdownButton<String>(
              value: widget.paraBirimi,
              isExpanded: true,
              items: _paraBirimleri.map((pb) => DropdownMenuItem(value: pb['sembol'], child: Text(pb['ad']!))).toList(),
              onChanged: (yeni) {
                if (yeni != null) {
                  widget.onParaBirimiDegistir(yeni);
                  Navigator.pop(c);
                }
              },
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(c), child: Text(t['save']!)),
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

    String raporMetni = "--- ${_yil} ${_aylar[_ay]} ${t['report']} ---\n"
        "${t['devir']} $pb${devir.toStringAsFixed(0)}\n"
        "${t['gelir']} $pb${gelir.toStringAsFixed(0)}\n"
        "${t['gider']} -$pb${gider.toStringAsFixed(0)}\n"
        "${t['net']} $pb${net.toStringAsFixed(0)}\n";

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
          ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devir = _devirHesapla(), gelir = _toplamGelir, gider = _toplamGider, net = devir + gelir - gider, pb = widget.paraBirimi;
    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']!, style: const TextStyle(fontSize: 14)),
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
                            subtitle: Text(g.tarih, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
