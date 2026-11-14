import 'package:flutter/material.dart';

void main() {
  runApp(const KasaKurumApp());
}

class KasaKurumApp extends StatefulWidget {
  const KasaKurumApp({super.key});

  @override
  State<KasaKurumApp> createState() => _KasaKurumAppState();
}

class _KasaKurumAppState extends State<KasaKurumApp> {
  String _paraBirimi = '₺';

  void _paraBirimiDegistir(String yeniBirim) {
    setState(() {
      _paraBirimi = yeniBirim;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasa Kurum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: AnaTakipEkrani(
        paraBirimi: _paraBirimi,
        onParaBirimiDegistir: _paraBirimiDegistir,
      ),
    );
  }
}

class AnaTakipEkrani extends StatefulWidget {
  final String paraBirimi;
  final Function(String) onParaBirimiDegistir;

  const AnaTakipEkrani({
    super.key,
    required this.paraBirimi,
    required this.onParaBirimiDegistir,
  });

  @override
  State<AnaTakipEkrani> createState() => _AnaTakipEkraniState();
}

class _AnaTakipEkraniState extends State<AnaTakipEkrani>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  double _varsayilanAidat = 500.0;
  final List<String> _personeller = ['Ahmet Yılmaz', 'Ayşe Demir'];
  final Map<String, double> _aktifOdemeler = {
    'Ahmet Yılmaz': 500.0,
    'Ayşe Demir': 0.0,
  };
  final List<Map<String, dynamic>> _giderler = [];

  final Map<String, String> t = {
    'settings': 'Ayarlar',
    'defaultFee': 'Varsayılan Aidat',
    'currency': 'Para Birimi',
    'cancel': 'İptal',
    'save': 'Kaydet',
    'delete': 'Sil',
    'editPayment': 'Ödeme Düzenle',
    'addPerson': 'Personel Ekle',
    'addExpense': 'Gider Ekle',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _toplamGelir {
    double toplam = 0;
    for (var kisi in _personeller) {
      toplam += _aktifOdemeler[kisi] ?? 0.0;
    }
    return toplam;
  }

  double get _toplamGider {
    double toplam = 0;
    for (var gider in _giderler) {
      toplam += (gider['tutar'] as double);
    }
    return toplam;
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
              controller: tutarCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: t['defaultFee']!),
            ),
            TextField(
              controller: birimCtrl,
              decoration: InputDecoration(labelText: t['currency']!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t['cancel']!),
          ),
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
    final ctrl = TextEditingController(
      text: (_aktifOdemeler[isim] ?? _varsayilanAidat).toString(),
    );
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$isim - ${t['editPayment']!}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})'),
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
              setState(() {
                _aktifOdemeler[isim] = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0;
              });
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
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Ad Soyad'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t['cancel']!),
          ),
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

  void _giderEklePenceresi() {
    final now = DateTime.now();
    final aciklamaCtrl = TextEditingController();
    final tutarCtrl = TextEditingController();
    final tarihCtrl = TextEditingController(
      text: '${now.day}.${now.month}.${now.year}',
    );
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t['addExpense']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: aciklamaCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            TextField(
              controller: tutarCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})'),
            ),
            TextField(
              controller: tarihCtrl,
              decoration: const InputDecoration(labelText: 'Tarih'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t['cancel']!),
          ),
          ElevatedButton(
            onPressed: () {
              final tutar = double.tryParse(tutarCtrl.text.replaceAll(',', '.'));
              if (aciklamaCtrl.text.trim().isNotEmpty && tutar != null && tutar > 0) {
                setState(() {
                  _giderler.add({
                    'aciklama': aciklamaCtrl.text.trim(),
                    'tutar': tutar,
                    'tarih': tarihCtrl.text.trim(),
                  });
                });
                Navigator.pop(c);
              }
            },
            child: Text(t['save']!),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kasaBakiye = _toplamGelir - _toplamGider;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Kurum Takip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _ayarlarPenceresi,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Aidat / Gelir'),
            Tab(icon: Icon(Icons.money_off), text: 'Giderler'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ozetKart('Gelir', _toplamGelir, Colors.green),
                _ozetKart('Gider', _toplamGider, Colors.red),
                _ozetKart('Kasa', kasaBakiye, Colors.teal),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Sekme: Personel Ödemeleri
                ListView.builder(
                  itemCount: _personeller.length,
                  itemBuilder: (context, index) {
                    final isim = _personeller[index];
                    final odenen = _aktifOdemeler[isim] ?? 0.0;
                    return ListTile(
                      leading: CircleAvatar(child: Text(isim[0].toUpperCase())),
                      title: Text(isim),
                      subtitle: Text(odenen > 0 ? 'Ödendi' : 'Ödenmedi'),
                      trailing: Text(
                        '${odenen.toStringAsFixed(2)} ${widget.paraBirimi}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: odenen > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      onTap: () => _odemeDuzenlePenceresi(isim),
                    );
                  },
                ),
                // 2. Sekme: Giderler
                _giderler.isEmpty
                    ? const Center(child: Text('Henüz gider eklenmedi.'))
                    : ListView.builder(
                        itemCount: _giderler.length,
                        itemBuilder: (context, index) {
