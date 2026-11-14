import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dil = prefs.getString('dil') ?? 'Türkçe';
      _paraBirimi = prefs.getString('paraBirimi') ?? '₺';
    });
  }

  Future<void> dilDegistir(String yeniDil) async {
    setState(() => _dil = yeniDil);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dil', yeniDil);
  }

  Future<void> paraBirimiDegistir(String yeniBirim) async {
    setState(() => _paraBirimi = yeniBirim);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paraBirimi', yeniBirim);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  final String id;
  final String aciklama;
  final double tutar;
  final String tarih;

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
        id: json['id'],
        aciklama: json['aciklama'],
        tutar: (json['tutar'] as num).toDouble(),
        tarih: json['tarih'],
      );
}

class AnaTakipEkrani extends StatefulWidget {
  final String seciliDil;
  final String paraBirimi;
  final Function(String) onDilDegistir;
  final Function(String) onParaBirimiDegistir;

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
  bool _yukleniyor = true;

  // 2006 - 2050 Yıl Aralığı
  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  final List<String> _aylar = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;

  List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};

  final List<String> _diller = [
    'Türkçe', 'English', 'Deutsch', 'Français', 'Español',
    'العربية', 'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'
  ];

  Map<String, String> get t {
    final sozlukler = {
      'English': {
        'title': '2006-2050 Financial Tracking',
        'devir': 'Previous Balance:',
        'gelir': 'Personnel Income:',
        'gider': 'Expenses:',
        'net': 'Next Month Balance:',
        'tab1': 'Personnel',
        'tab2': 'Expenses',
        'addPerson': '+ Add Personnel',
        'addExpense': '+ Add Expense',
        'delete': 'Delete',
        'save': 'Save',
        'cancel': 'Cancel',
        'settings': 'Settings',
        'defaultFee': 'Default Amount:',
        'currency': 'Currency Symbol:',
        'editPayment': 'Enter Payment Amount',
        'paid': 'Paid:',
        'waiting': 'Waiting for payment',
        'savedMsg': 'All data saved successfully!',
        'pdfTitle': 'Monthly Financial Report',
        'exportPdf': 'Export PDF',
      },
      'Türkçe': {
        'title': '2006-2050 Kasa Takip',
        'devir': 'Geçen Aydan Devir:',
        'gelir': 'Personel Geliri:',
        'gider': 'Aylık Gider:',
        'net': 'Sonraki Aya Devir:',
        'tab1': 'Personel Listesi',
        'tab2': 'Giderler',
        'addPerson': '+ Yeni Personel Ekle',
        'addExpense': '+ Gider Ekle (Tarihli)',
        'delete': 'Sil',
        'save': 'Kaydet',
        'cancel': 'İptal',
        'settings': 'Ayarlar',
        'defaultFee': 'Varsayılan Tutar:',
        'currency': 'Para Birimi:',
        'editPayment': 'Ödeme Tutarını Girin',
        'paid': 'Ödenen:',
        'waiting': 'Ödeme bekleniyor',
        'savedMsg': 'Tüm veriler hafızaya kaydedildi!',
        'pdfTitle': 'Aylık Kasa Raporu',
        'exportPdf': 'PDF Olarak İndir / Paylaş',
      }
    };

    return sozlukler[widget.seciliDil] ?? sozlukler['English']!;
  }

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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _verileriKaydet();
    }
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();

    final kayitliPersoneller = prefs.getStringList('personeller');
    if (kayitliPersoneller != null) {
      _personeller = kayitliPersoneller;
    }

    _varsayilanAidat = prefs.getDouble('varsayilanAidat') ?? 500.0;

    final odemelerJson = prefs.getString('odemeler');
    if (odemelerJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(odemelerJson);
      _odemeler.clear();
      decoded.forEach((ayKey, kisiMap) {
        _odemeler[ayKey] = (kisiMap as Map<String, dynamic>).map(
          (kisi, tutar) => MapEntry(kisi, (tutar as num).toDouble()),
        );
      });
    }

    final giderlerJson = prefs.getString('giderler');
    if (giderlerJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(giderlerJson);
      _giderler.clear();
      decoded.forEach((ayKey, liste) {
        _giderler[ayKey] = (liste as List)
            .map((item) => Gider.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }

    setState(() {
      _yukleniyor = false;
    });
  }

  Future<void> _verileriKaydet({bool bildirimGoster = false}) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('personeller', _personeller);
    await prefs.setDouble('varsayilanAidat', _varsayilanAidat);
    await prefs.setString('odemeler', jsonEncode(_odemeler));

    final Map<String, dynamic> giderlerMap = {};
    _giderler.forEach((ayKey, liste) {
      giderlerMap[ayKey] = liste.map((g) => g.toJson()).toList();
    });
    await prefs.setString('giderler', jsonEncode(giderlerMap));

    if (bildirimGoster && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t['savedMsg']!),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Standart PDF fontlarında karakter hatası olmaması için dönüştürücü
  String _pdfMetin(String metin) {
    return metin
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C')
        .replaceAll('₺', 'TL');
  }

  // SEÇİLİ AY İÇİN PDF RAPORU OLUŞTURMA VE İNDİRME/PAYLAŞMA
  Future<void> _pdfOlusturVeIndir() async {
    final pdf = pw.Document();
    final devir = _devirHesapla();
    final gelir = _toplamGelir;
    final gider = _toplamGider;
    final net = devir + gelir - gider;
    final pb = _pdfMetin(widget.paraBirimi);
    final donemBaslik = '${_pdfMetin(_aylar[_ay])} $_yil';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _pdfMetin('${t['pdfTitle']} - $donemBaslik'),
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // KASA ÖZET TABLOSU
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
