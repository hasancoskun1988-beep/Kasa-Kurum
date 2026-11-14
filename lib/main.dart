import 'package:flutter/material.dart';

void main() {
  runApp(const KurumKasaApp());
}

class KurumKasaApp extends StatefulWidget {
  const KurumKasaApp({Key? key}) : super(key: key);

  @override
  State<KurumKasaApp> createState() => _KurumKasaAppState();
}

class _KurumKasaAppState extends State<KurumKasaApp> {
  String _dil = 'Türkçe';
  String _paraBirimi = '₺';

  void dilDegistir(String yeniDil) {
    setState(() => _dil = yeniDil);
  }

  void paraBirimiDegistir(String yeniBirim) {
    setState(() => _paraBirimi = yeniBirim);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
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
}

class AnaTakipEkrani extends StatefulWidget {
  final String seciliDil;
  final String paraBirimi;
  final Function(String) onDilDegistir;
  final Function(String) onParaBirimiDegistir;

  const AnaTakipEkrani({
    Key? key,
    required this.seciliDil,
    required this.paraBirimi,
    required this.onDilDegistir,
    required this.onParaBirimiDegistir,
  }) : super(key: key);

  @override
  State<AnaTakipEkrani> createState() => _AnaTakipEkraniState();
}

class _AnaTakipEkraniState extends State<AnaTakipEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  final List<String> _aylar = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
  ];

  int _yil = 2026;
  int _ay = 0;
  double _varsayilanAidat = 500.0;

  final List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};

  final List<String> _diller = [
    'Türkçe', 'English', 'Deutsch', 'Français', 'Español',
    'العربية', 'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'
  ];

  Map<String, String> get t {
    final Map<String, Map<String, String>> sozlukler = {
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
      },
      'Deutsch': {
        'title': '2006-2050 Finanztracker',
        'devir': 'Übertrag Vormonat:',
        'gelir': 'Personaleinnahmen:',
        'gider': 'Ausgaben:',
        'net': 'Neuer Saldo:',
        'tab1': 'Personal',
        'tab2': 'Ausgaben',
        'addPerson': '+ Personal Hinzufügen',
        'addExpense': '+ Ausg. Hinzufügen',
        'delete': 'Löschen',
        'save': 'Speichern',
        'cancel': 'Abbrechen',
        'settings': 'Einstellungen',
        'defaultFee': 'Standardbetrag:',
        'currency': 'Währungssymbol:',
        'editPayment': 'Zahlungsbetrag eingeben',
        'paid': 'Bezahlt:',
        'waiting': 'Warten auf Zahlung',
      },
      'Français': {
        'title': 'Suivi Financier 2006-2050',
        'devir': 'Report Précédent:',
        'gelir': 'Revenus Personnel:',
        'gider': 'Dépenses:',
        'net': 'Solde Final:',
        'tab1': 'Personnel',
        'tab2': 'Dépenses',
        'addPerson': '+ Ajouter Personnel',
        'addExpense': '+ Ajouter Dépense',
        'delete': 'Supprimer',
        'save': 'Enregistrer',
        'cancel': 'Annuler',
        'settings': 'Paramètres',
        'defaultFee': 'Montant par défaut:',
        'currency': 'Symbole Monétaire:',
        'editPayment': 'Entrer le montant',
        'paid': 'Payé:',
        'waiting': 'En attente',
      },
      'Español': {
        'title': 'Control Financiero 2006-2050',
        'devir': 'Saldo Anterior:',
        'gelir': 'Ingresos Personal:',
        'gider': 'Gastos:',
        'net': 'Saldo Siguiente:',
        'tab1': 'Personal',
        'tab2': 'Gastos',
        'addPerson': '+ Añadir Personal',
        'addExpense': '+ Añadir Gasto',
        'delete': 'Eliminar',
        'save': 'Guardar',
        'cancel': 'Cancelar',
        'settings': 'Ajustes',
        'defaultFee': 'Monto predeterminado:',
        'currency': 'Símbolo de Moneda:',
        'editPayment': 'Ingrese el monto',
        'paid': 'Pagado:',
        'waiting': 'Esperando pago',
      },
      'العربية': {
        'title': 'متابعة الميزانية 2006-2050',
        'devir': 'الرصيد السابق:',
        'gelir': 'إيرادات الموظفين:',
        'gider': 'المصروفات:',
        'net': 'الرصيد القادم:',
        'tab1': 'الموظفون',
        'tab2': 'المصروفات',
        'addPerson': '+ إضافة موظف',
        'addExpense': '+ إضافة مصروف',
        'delete': 'حذف',
        'save': 'حفظ',
        'cancel': 'إلغاء',
        'settings': 'الإعدادات',
        'defaultFee': 'المبلغ الافتراضي:',
        'currency': 'رمز العملة:',
        'editPayment': 'أدخل مبلغ الدفع',
        'paid': 'مدفوع:',
        'waiting': 'في انتظار الدفع',
      },
      'Русский': {
        'title': 'Учет финансов 2006-2050',
        'devir': 'Прошлый остаток:',
        'gelir': 'Доходы персонала:',
        'gider': 'Расходы:',
        'net': 'Итоговый остаток:',
        'tab1': 'Персонал',
        'tab2': 'Расходы',
        'addPerson': '+ Добавить сотрудника',
        'addExpense': '+ Добавить расход',
        'delete': 'Удалить',
        'save': 'Сохранить',
        'cancel': 'Отмена',
        'settings': 'Настройки',
        'defaultFee': 'Сумма по умолчанию:',
        'currency': 'Символ валюты:',
        'editPayment': 'Введите сумму платежа',
        'paid': 'Оплачено:',
        'waiting': 'Ожидание оплаты',
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
      }
    };

    return sozlukler[widget.seciliDil] ?? sozlukler['English']!;
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
            TextField(
              controller: birimCtrl,
              decoration: InputDecoration(labelText: t['currency']),
            ),
            TextField(
              controller: tutarCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: t['defaultFee']),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(tutarCtrl.text.replaceAll(',', '.'));
              if (yeniTutar != null && yeniTutar >= 0) {
                setState(() => _varsayilanAidat = yeniTutar);
              }
              if (birimCtrl.text.trim().isNotEmpty) {
                widget.onParaBirimiDegistir(birimCtrl.text.trim());
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
    double mevcutTutar = _aktifOdemeler[isim] ?? _varsayilanAidat;
    final ctrl = TextEditingController(text: mevcutTutar.toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$isim - ${t['editPayment']}'),
        content: TextField(
          controller: ctrl,
