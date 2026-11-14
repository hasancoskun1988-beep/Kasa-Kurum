import 'package:flutter/material.dart';

void main() => runApp(const KurumKasaApp());

class KurumKasaApp extends StatefulWidget {
  const KurumKasaApp({super.key});
  @override
  State<KurumKasaApp> createState() => _KurumKasaAppState();
}

class _KurumKasaAppState extends State<KurumKasaApp> {
  String _dil = 'Türkçe';
  String _paraBirimi = '₺';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
      home: AnaTakipEkrani(
        seciliDil: _dil,
        paraBirimi: _paraBirimi,
        onDilDegistir: (yeniDil) => setState(() => _dil = yeniDil),
        onParaBirimiDegistir: (yeniBirim) => setState(() => _paraBirimi = yeniBirim),
      ),
    );
  }
}

class Gider {
  final String id, aciklama, tarih;
  final double tutar;
  Gider({required this.id, required this.aciklama, required this.tutar, required this.tarih});
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

class _AnaTakipEkraniState extends State<AnaTakipEkrani> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  final List<String> _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;
  final List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};
  final List<String> _diller = ['Türkçe', 'English', 'Deutsch', 'Français', 'Español', 'العربية', 'Русский'];

  Map<String, String> get t {
    final s = {
      'English': {'title': '2006-2050 Financial Tracking', 'devir': 'Previous Balance:', 'gelir': 'Income:', 'gider': 'Expenses:', 'net': 'Next Balance:', 'tab1': 'Personnel', 'tab2': 'Expenses', 'addPerson': '+ Add Personnel', 'addExpense': '+ Add Expense', 'delete': 'Delete', 'save': 'Save', 'cancel': 'Cancel', 'settings': 'Settings', 'defaultFee': 'Default Amount:', 'currency': 'Currency:', 'editPayment': 'Payment Amount', 'paid': 'Paid:', 'waiting': 'Waiting'},
      'Deutsch': {'title': '2006-2050 Finanztracker', 'devir': 'Übertrag:', 'gelir': 'Einnahmen:', 'gider': 'Ausgaben:', 'net': 'Neuer Saldo:', 'tab1': 'Personal', 'tab2': 'Ausgaben', 'addPerson': '+ Personal', 'addExpense': '+ Ausgabe', 'delete': 'Löschen', 'save': 'Speichern', 'cancel': 'Abbrechen', 'settings': 'Einstellungen', 'defaultFee': 'Standardbetrag:', 'currency': 'Währung:', 'editPayment': 'Zahlungsbetrag', 'paid': 'Bezahlt:', 'waiting': 'Offen'},
      'Français': {'title': 'Suivi Financier 2006-2050', 'devir': 'Report:', 'gelir': 'Revenus:', 'gider': 'Dépenses:', 'net': 'Solde Final:', 'tab1': 'Personnel', 'tab2': 'Dépenses', 'addPerson': '+ Personnel', 'addExpense': '+ Dépense', 'delete': 'Supprimer', 'save': 'Enregistrer', 'cancel': 'Annuler', 'settings': 'Paramètres', 'defaultFee': 'Montant défaut:', 'currency': 'Devise:', 'editPayment': 'Montant', 'paid': 'Payé:', 'waiting': 'En attente'},
      'Español': {'title': 'Control Financiero 2006-2050', 'devir': 'Saldo Anterior:', 'gelir': 'Ingresos:', 'gider': 'Gastos:', 'net': 'Saldo Final:', 'tab1': 'Personal', 'tab2': 'Gastos', 'addPerson': '+ Personal', 'addExpense': '+ Gasto', 'delete': 'Eliminar', 'save': 'Guardar', 'cancel': 'Cancelar', 'settings': 'Ajustes', 'defaultFee': 'Monto defecto:', 'currency': 'Moneda:', 'editPayment': 'Monto', 'paid': 'Pagado:', 'waiting': 'Pendiente'},
      'العربية': {'title': 'متابعة الميزانية 2006-2050', 'devir': 'الرصيد السابق:', 'gelir': 'الإيرادات:', 'gider': 'المصروفات:', 'net': 'الرصيد القادم:', 'tab1': 'الموظفون', 'tab2': 'المصروفات', 'addPerson': '+ إضافة موظف', 'addExpense': '+ إضافة مصروف', 'delete': 'حذف', 'save': 'حفظ', 'cancel': 'إلغاء', 'settings': 'الإعدادات', 'defaultFee': 'المبلغ الافتراضي:', 'currency': 'العملة:', 'editPayment': 'مبلغ الدفع', 'paid': 'مدفوع:', 'waiting': 'في الانتظار'},
      'Русский': {'title': 'Учет финансов 2006-2050', 'devir': 'Прошлый остаток:', 'gelir': 'Доходы:', 'gider': 'Расходы:', 'net': 'Итоговый остаток:', 'tab1': 'Персонал', 'tab2': 'Расходы', 'addPerson': '+ Сотрудник', 'addExpense': '+ Расход', 'delete': 'Удалить', 'save': 'Сохранить', 'cancel': 'Отмена', 'settings': 'Настройки', 'defaultFee': 'Сумма:', 'currency': 'Валюта:', 'editPayment': 'Сумма платежа', 'paid': 'Оплачено:', 'waiting': 'Ожидание'},
      'Türkçe': {'title': '2006-2050 Kasa Takip', 'devir': 'Geçen Aydan Devir:', 'gelir': 'Personel Geliri:', 'gider': 'Aylık Gider:', 'net': 'Sonraki Aya Devir:', 'tab1': 'Personel Listesi', 'tab2': 'Giderler', 'addPerson': '+ Yeni Personel Ekle', 'addExpense': '+ Gider Ekle', 'delete': 'Sil', 'save': 'Kaydet', 'cancel': 'İptal', 'settings': 'Ayarlar', 'defaultFee': 'Varsayılan Tutar:', 'currency': 'Para Birimi:', 'editPayment': 'Ödeme Tutarı', 'paid': 'Ödenen:', 'waiting': 'Ödeme bekleniyor'},
    };
    return s[widget.seciliDil] ?? s['English']!;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
        double g = (_odemeler[key] ?? {}).values.fold(0.0, (s, v) => s + v);
        double gi = (_giderler[key] ?? []).fold(0.0, (s, x) => s + x.tutar);
        d += (g - gi);
      }
    }
    return d;
  }

  void _ayarlarPenceresi() {
    final tutarCtrl = TextEditingController(text: _varsayilanAidat.toString());
    final birimCtrl = TextEditingController(text: widget.paraBirimi);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['settings']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: birimCtrl, decoration: InputDecoration(labelText: t['currency'])),
            TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t['defaultFee'])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(tutarCtrl.text.replaceAll(',', '.'));
              if (yeniTutar != null && yeniTutar >= 0) setState(() => _varsayilanAidat = yeniTutar);
              if (birimCtrl.text.trim().isNotEmpty) widget.onParaBirimiDegistir(birimCtrl.text.trim());
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
          TextButton(
            onPressed: () {
              setState(() => _aktifOdemeler[isim] = 0.0);
              Navigator.pop(c);
            },
            child: Text(t['delete']!, style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _aktifOdemeler[isim] = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0);
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
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
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) setState(() => _personeller.add(ctrl.text.trim()));
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  void _giderEklePenceresi() {
    final now = DateTime.now();
    final aciklamaCtrl = TextEditingController();
    final tutarCtrl = TextEditingController();
    final tarihCtrl = TextEditingController(text: '${now.day}.${now.month}.${now.year}');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addExpense']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aciklamaCtrl, decoration: const InputDecoration(labelText: 'Açıklama')),
