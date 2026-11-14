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
