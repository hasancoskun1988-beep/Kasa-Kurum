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

  Gider({required this.id, required this.aciklama, required this.tutar, required this.tarih});
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

class _AnaTakipEkraniState extends State<AnaTakipEkrani> with SingleTickerProviderStateMixin {
  late TabController _tab;

  // 2006 - 2050 Yıl Aralığı
  final List<int> _yillar = List.generate(45, (i) => 2006 + i);
  
  final List<String> _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;

  // Dinamik Personel Listesi
  List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];

  // Kayıtlar: Ay anahtarına göre (Örn: "2026-0") personellerin ödemeleri
  final Map<String, Map<String, double>> _odemeler = {};
  
  // Kayıtlar: Ay anahtarına göre gider listesi
  final Map<String, List<Gider>> _giderler = {};

  // Dünya Dilleri Listesi
  final List<String> _diller = [
    'Türkçe', 'English', 'Deutsch', 'Français', 'Español', 
    'العربية', 'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'
  ];

  // Kapsamlı Çeviri Sözlüğü (Eksik diller İngilizceye fallback yapar)
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
        'cancel': 'Aborted',
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

  // Ayarlar Penceresi (Dil, Para Birimi ve Varsayılan Tutar)
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t['defaultFee']),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(tutarCtrl.text);
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

  // Personel Ödemesini Elle Düzenleme Penceresi
  void _odemeDuzenlePenceresi(String isim) {
    double mevcutTutar = _aktifOdemeler[isim] ?? _varsayilanAidat;
    final ctrl = TextEditingController(text: mevcutTutar.toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$isim - ${t['editPayment']}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: '${t['defaultFee']} (${widget.paraBirimi})'),
        ),
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
              final girilenTutar = double.tryParse(ctrl.text) ?? 0.0;
              setState(() => _aktifOdemeler[isim] = girilenTutar);
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  // Personel Ekleme Penceresi
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
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _personeller.add(ctrl.text.trim()));
              }
              Navigator.pop(c);
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  // Gider Ekleme Penceresi
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
            TextField(controller: aciklamaCtrl, decoration: const InputDecoration(labelText: 'Açıklama (Örn: Elektrik)')),
            TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})')),
            TextField(controller: tarihCtrl, decoration: const InputDecoration(labelText: 'Tarih (GG.AA.YYYY)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(t['cancel']!)),
          ElevatedButton(
            onPressed: () {
              final tutar = double.tryParse(tutarCtrl.text) ?? 0.0;
              if (aciklamaCtrl.text.trim().isNotEmpty && tutar > 0) {
                setState(() {
                  _aktifGiderler.insert(
                    0,
                    Gider(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      aciklama: aciklamaCtrl.text.trim(),
                      tutar: tutar,
                      tarih: tarihCtrl.text.trim(),
                    ),
                  );
                });
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
    final devir = _devirHesapla();
    final gelir = _toplamGelir;
    final gider = _toplamGider;
    final net = devir + gelir - gider;
    final pb = widget.paraBirimi;

    return Scaffold(
      appBar: AppBar(
        title: Text(t['title']!, style: const TextStyle(fontSize: 14)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: t['settings'],
            onPressed: _ayarlarPenceresi,
          ),
          DropdownButton<String>(
            value: widget.seciliDil,
            dropdownColor: Colors.indigo.shade50,
            underline: const SizedBox(),
            items: _diller.map((dil) => DropdownMenuItem(value: dil, child: Text(dil, style: const TextStyle(fontSize: 12)))).toList(),
            onChanged: (yeni) => widget.onDilDegistir(yeni!),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Yıl ve Ay Seçici
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.indigo.shade50,
            child: Row(
              children: [
                DropdownButton<int>(
                  value: _yil,
                  items: _yillar.map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) => setState(() => _yil = v!),
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
                          onSelected: (_) => setState(() => _ay = i),
                        ),
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Özet Kartı
          Card(
            margin: const EdgeInsets.all(10),
            color: Colors.indigo.shade800,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t['devir']!, style: const TextStyle(color: Colors.amberAccent)),
                    Text('$pb${devir.toStringAsFixed(0)}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t['gelir']!, style: const TextStyle(color: Colors.greenAccent)),
                    Text('$pb${gelir.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t['gider']!, style: const TextStyle(color: Colors.redAccent)),
                    Text('-$pb${gider.toStringAsFixed(0)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(color: Colors.white24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t['net']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('$pb${net.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tab,
            tabs: [
              Tab(text: t['tab1']!),
              Tab(text: t['tab2']!),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // PERSONEL GELİR LİSTESİ
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        onPressed: _personelEklePenceresi,
                        icon: const Icon(Icons.person_add),
                        label: Text(t['addPerson']!),
                      ),
                    ),
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
                              leading: IconButton(
                                icon: Icon(
                                  odedi ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: odedi ? Colors.green : Colors.grey,
                                ),
                                onPressed: () => _odemeDuzenlePenceresi(isim),
                              ),
                              title: Text(isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(odedi ? '${t['paid']} $pb$odenen' : t['waiting']!),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _odemeDuzenlePenceresi(isim),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _personeller.removeAt(index);
                                        _aktifOdemeler.remove(isim);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // GİDERLER LİSTESİ
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                        onPressed: _giderEklePenceresi,
                        icon: const Icon(Icons.add),
                        label: Text(t['addExpense']!),
                      ),
                    ),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('-$pb${g.tutar.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => setState(() => _aktifGiderler.removeAt(index)),
                                  ),
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
