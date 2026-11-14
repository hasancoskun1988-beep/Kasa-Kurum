import 'package:flutter/material.dart';

void main() => runApp(const KasaKurumApp());

class KasaKurumApp extends StatefulWidget {
  const KasaKurumApp({super.key});
  @override
  State<KasaKurumApp> createState() => _KasaKurumAppState();
}

class _KasaKurumAppState extends State<KasaKurumApp> {
  String _paraBirimi = '₺';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasa Kurum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), useMaterial3: true),
      home: AnaTakipEkrani(
        paraBirimi: _paraBirimi,
        onParaBirimiDegistir: (b) => setState(() => _paraBirimi = b),
      ),
    );
  }
}

class AnaTakipEkrani extends StatefulWidget {
  final String paraBirimi;
  final Function(String) onParaBirimiDegistir;
  const AnaTakipEkrani({super.key, required this.paraBirimi, required this.onParaBirimiDegistir});

  @override
  State<AnaTakipEkrani> createState() => _AnaTakipEkraniState();
}

class _AnaTakipEkraniState extends State<AnaTakipEkrani> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _varsayilanAidat = 500.0;
  final List<String> _personeller = ['Ahmet Yılmaz', 'Ayşe Demir'];
  final Map<String, double> _aktifOdemeler = {'Ahmet Yılmaz': 500.0, 'Ayşe Demir': 0.0};
  final List<Map<String, dynamic>> _giderler = [];

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

  double get _toplamGelir => _personeller.fold(0.0, (sum, k) => sum + (_aktifOdemeler[k] ?? 0.0));
  double get _toplamGider => _giderler.fold(0.0, (sum, g) => sum + (g['tutar'] as double));

  void _ayarlarPenceresi() {
    final tutarCtrl = TextEditingController(text: _varsayilanAidat.toString());
    final birimCtrl = TextEditingController(text: widget.paraBirimi);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Varsayılan Aidat')),
            TextField(controller: birimCtrl, decoration: const InputDecoration(labelText: 'Para Birimi')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final yeniTutar = double.tryParse(tutarCtrl.text.replaceAll(',', '.'));
              if (yeniTutar != null && yeniTutar >= 0) setState(() => _varsayilanAidat = yeniTutar);
              if (birimCtrl.text.trim().isNotEmpty) widget.onParaBirimiDegistir(birimCtrl.text.trim());
              Navigator.pop(c);
            },
            child: const Text('Kaydet'),
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
        title: Text('$isim - Ödeme Düzenle'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})')),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _aktifOdemeler[isim] = 0.0);
              Navigator.pop(c);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _aktifOdemeler[isim] = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0.0);
              Navigator.pop(c);
            },
            child: const Text('Kaydet'),
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
        title: const Text('Personel Ekle'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Ad Soyad')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) setState(() => _personeller.add(ctrl.text.trim()));
              Navigator.pop(c);
            },
            child: const Text('Kaydet'),
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
        title: const Text('Gider Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: aciklamaCtrl, decoration: const InputDecoration(labelText: 'Açıklama')),
            TextField(controller: tutarCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Tutar (${widget.paraBirimi})')),
            TextField(controller: tarihCtrl, decoration: const InputDecoration(labelText: 'Tarih')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              final tutar = double.tryParse(tutarCtrl.text.replaceAll(',', '.'));
              if (aciklamaCtrl.text.trim().isNotEmpty && tutar != null && tutar > 0) {
                setState(() => _giderler.add({'aciklama': aciklamaCtrl.text.trim(), 'tutar': tutar, 'tarih': tarihCtrl.text.trim()}));
                Navigator.pop(c);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _ozetKart(String baslik, double tutar, Color renk) {
    return Column(
      children: [
        Text(baslik, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('${tutar.toStringAsFixed(2)} ${widget.paraBirimi}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: renk)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasa Kurum Takip'),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _ayarlarPenceresi)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(icon: Icon(Icons.people), text: 'Aidat / Gelir'), Tab(icon: Icon(Icons.money_off), text: 'Giderler')],
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
                _ozetKart('Kasa', _toplamGelir - _toplamGider, Colors.teal),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: _personeller.length,
                  itemBuilder: (context, index) {
                    final isim = _personeller[index];
                    final odenen = _aktifOdemeler[isim] ?? 0.0;
                    return ListTile(
                      leading: CircleAvatar(child: Text(isim.toUpperCase())),
                      title: Text(isim),
                      subtitle: Text(odenen > 0 ? 'Ödendi' : 'Ödenmedi'),
                      trailing: Text('${odenen.toStringAsFixed(2)} ${widget.paraBirimi}', style: TextStyle(fontWeight: FontWeight.bold, color: odenen > 0 ? Colors.green : Colors.red)),
                      onTap: () => _odemeDuzenlePenceresi(isim),
                    );
                  },
                ),
                _giderler.isEmpty
                    ? const Center(child: Text('Henüz gider eklenmedi.'))
                    : ListView.builder(
                        itemCount: _giderler.length,
                        itemBuilder: (context, index) {
                          final g = _giderler[index];
                          return ListTile(
                            leading: const Icon(Icons.receipt_long, color: Colors.red),
                            title: Text(g['aciklama']),
                            subtitle: Text(g['tarih']),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _giderler.removeAt(index))),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.index == 0 ? _personelEklePenceresi() : _giderEklePenceresi(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ekle'),
      ),
    );
  }
}
