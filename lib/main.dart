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
  int _yil = 2026, _ay = 0;
  double _varsayilanAidat = 500.0;
  List<String> _personeller = ['Ahmet Yılmaz', 'Mehmet Demir', 'Ayşe Kaya'];
  final Map<String, Map<String, double>> _odemeler = {};
  final Map<String, List<Gider>> _giderler = {};
  final List<String> _diller = [
    'Türkçe', 'English', 'Deutsch', 'Français', 'Español', 'العربية',
    'Русский', '中文', '日本語', 'Português', 'Italiano', 'हिन्दी'
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
        'cancel': 'İptal', 'settings': 'Ayarlar', 'defaultFee': 'Varsayılan Tutar:', 'currency': 'Para Birimi:',
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
        'cancel': 'Cancel', 'settings': 'Settings', 'defaultFee': 'Default Amount:', 'currency': 'Currency Symbol:',
        'editPayment': 'Enter Payment Amount', 'paid': 'Paid:', 'waiting': 'Waiting for payment',
        'savedMsg': 'All data saved to device!', 'report': 'Monthly Report',
        'fullName': 'Full Name', 'desc': 'Description (e.g. Electricity)', 'amount': 'Amount', 'date': 'Date (DD.MM.YYYY)',
        'copyText': 'Copy Text', 'copiedMsg': 'Report copied!', 'saveDownloads': 'Save to Downloads',
        'noExpense': 'No recorded expenses.',
        'welcomeTitle': 'Welcome to Financial Tracking',
        'welcomeMsg': 'Easily manage adding personnel & income, monthly expenses, and carried-over balances from 2006 to 2050, and generate instant monthly reports.',
        'startBtn': 'Open Cashbook',
      },
      'Deutsch': {
        'title': '2006-2050 Kassenbuch', 'devir': 'Übertrag Vormonat:', 'gelir': 'Personaleinnahmen:',
        'gider': 'Ausgaben:', 'net': 'Übertrag Folgemonat:', 'tab1': 'Personal & Einnahmen', 'tab2': 'Ausgaben',
        'addPerson': '+ Personal hinzufügen', 'addExpense': '+ Ausgabe hinzufügen', 'delete': 'Löschen', 'save': 'Speichern',
        'cancel': 'Abbrechen', 'settings': 'Einstellungen', 'defaultFee': 'Standardbetrag:', 'currency': 'Währung:',
        'editPayment': 'Zahlungsbetrag eingeben', 'paid': 'Bezahlt:', 'waiting': 'Zahlung ausstehend',
        'savedMsg': 'Alle Daten gespeichert!', 'report': 'Monatsbericht',
        'fullName': 'Vor- und Nachname', 'desc': 'Beschreibung (z.B. Strom)', 'amount': 'Betrag', 'date': 'Datum (TT.MM.JJJJ)',
        'copyText': 'Text kopieren', 'copiedMsg': 'Bericht kopiert!', 'saveDownloads': 'In Downloads speichern',
        'noExpense': 'Keine Ausgaben erfasst.',
        'welcomeTitle': 'Willkommen im Kassenbuch',
        'welcomeMsg': 'Verwalten Sie Personal & Einnahmen, monatliche Ausgaben und Überträge von 2006 bis 2050 und erstellen Sie sofortige Monatsberichte.',
        'startBtn': 'Kasse öffnen',
      },
      'Français': {
        'title': 'Suivi de Caisse 2006-2050', 'devir': 'Solde Précédent:', 'gelir': 'Revenus Personnel:',
        'gider': 'Dépenses:', 'net': 'Solde Suivant:', 'tab1': 'Personnel et Revenus', 'tab2': 'Dépenses',
        'addPerson': '+ Ajouter Personnel', 'addExpense': '+ Ajouter Dépense', 'delete': 'Supprimer', 'save': 'Enregistrer',
        'cancel': 'Annuler', 'settings': 'Paramètres', 'defaultFee': 'Montant par défaut:', 'currency': 'Devise:',
        'editPayment': 'Entrer le montant', 'paid': 'Payé:', 'waiting': 'En attente',
        'savedMsg': 'Données enregistrées!', 'report': 'Rapport Mensuel',
        'fullName': 'Nom et Prénom', 'desc': 'Description (ex: Électricité)', 'amount': 'Montant', 'date': 'Date (JJ.MM.AAAA)',
        'copyText': 'Copier le texte', 'copiedMsg': 'Rapport copié!', 'saveDownloads': 'Enregistrer',
        'noExpense': 'Aucune dépense enregistrée.',
        'welcomeTitle': 'Bienvenue dans Suivi de Caisse',
        'welcomeMsg': 'Gérez facilement l\'ajout de personnel et revenus, les dépenses mensuelles et les soldes reportés de 2006 à 2050.',
        'startBtn': 'Ouvrir la Caisse',
      },
      'Español': {
        'title': 'Control de Caja 2006-2050', 'devir': 'Saldo Anterior:', 'gelir': 'Ingresos Personal:',
        'gider': 'Gastos:', 'net': 'Saldo Siguiente:', 'tab1': 'Personal e Ingresos', 'tab2': 'Gastos',
        'addPerson': '+ Añadir Personal', 'addExpense': '+ Añadir Gasto', 'delete': 'Eliminar', 'save': 'Guardar',
        'cancel': 'Cancelar', 'settings': 'Ajustes', 'defaultFee': 'Monto Predeterminado:', 'currency': 'Moneda:',
        'editPayment': 'Ingrese el monto', 'paid': 'Pagado:', 'waiting': 'Pendiente de pago',
        'savedMsg': '¡Datos guardados!', 'report': 'Informe Mensual',
        'fullName': 'Nombre Completo', 'desc': 'Descripción (ej. Electricidad)', 'amount': 'Monto', 'date': 'Fecha (DD.MM.AAAA)',
        'copyText': 'Copiar texto', 'copiedMsg': '¡Informe copiado!', 'saveDownloads': 'Guardar en Descargas',
        'noExpense': 'No hay gastos registrados.',
        'welcomeTitle': 'Bienvenido a Control de Caja',
        'welcomeMsg': 'Gestione personal e ingresos, gastos mensuales y saldos acumulados entre 2006 y 2050 con informes instantáneos.',
        'startBtn': 'Abrir Caja',
      },
      'العربية': {
        'title': 'تتبع الصندوق 2006-2050', 'devir': 'الرصيد السابق:', 'gelir': 'دخل الموظفين:',
        'gider': 'المصاريف:', 'net': 'الرصيد القادم:', 'tab1': 'إضافة موظف والإيرادات', 'tab2': 'المصاريف',
        'addPerson': '+ إضافة موظف', 'addExpense': '+ إضافة مصروف', 'delete': 'حذف', 'save': 'حفظ',
        'cancel': 'إلغاء', 'settings': 'الإعدادات', 'defaultFee': 'المبلغ الافتراضي:', 'currency': 'العملة:',
        'editPayment': 'أدخل مبلغ الدفع', 'paid': 'مدفوع:', 'waiting': 'في انتظار الدفع',
        'savedMsg': 'تم حفظ البيانات!', 'report': 'التقرير الشهري',
        'fullName': 'الاسم الكامل', 'desc': 'الوصف (مثال: كهرباء)', 'amount': 'المبلغ', 'date': 'التاريخ',
        'copyText': 'نسخ النص', 'copiedMsg': 'تم نسخ التقرير!', 'saveDownloads': 'حفظ في التنزيلات',
        'noExpense': 'لا توجد مصاريف مسجلة.',
        'welcomeTitle': 'مرحباً بكم في تتبع الصندوق',
        'welcomeMsg': 'قم بإدارة الموظفين والإيرادات والمصاريف الشهرية والأرصدة المرحلة من 2006 إلى 2050 واستخراج التقارير بسهولة.',
        'startBtn': 'فتح الصندوق',
      },
      'Русский': {
        'title': 'Учет Кассы 2006-2050', 'devir': 'Остаток с прошлого мес.:', 'gelir': 'Доход от персонала:',
        'gider': 'Расходы:', 'net': 'Остаток на след. мес.:', 'tab1': 'Персонал и доходы', 'tab2': 'Расходы',
        'addPerson': '+ Добавить сотрудника', 'addExpense': '+ Добавить расход', 'delete': 'Удалить', 'save': 'Сохранить',
        'cancel': 'Отмена', 'settings': 'Настройки', 'defaultFee': 'Сумма по умолчанию:', 'currency': 'Валюта:',
        'editPayment': 'Введите сумму', 'paid': 'Оплачено:', 'waiting': 'Ожидает оплаты',
        'savedMsg': 'Данные сохранены!', 'report': 'Ежемесячный отчет',
        'fullName': 'Имя и Фамилия', 'desc': 'Описание (напр. Электричество)', 'amount': 'Сумма', 'date': 'Дата (ДД.ММ.ГГГГ)',
        'copyText': 'Копировать текст', 'copiedMsg': 'Отчет скопирован!', 'saveDownloads': 'Сохранить в Загрузки',
        'noExpense': 'Нет записанных расходов.',
        'welcomeTitle': 'Добро пожаловать в Учет Кассы',
        'welcomeMsg': 'Управляйте персоналом и доходами, расходами и переходящими остатками с 2006 по 2050 год и формируйте отчеты в один клик.',
        'startBtn': 'Открыть кассу',
      },
      '中文': {
        'title': '2006-2050 财务追踪', 'devir': '上月结转:', 'gelir': '人员收入:',
        'gider': '支出:', 'net': '下月结转:', 'tab1': '添加人员与收入', 'tab2': '支出',
        'addPerson': '+ 添加人员', 'addExpense': '+ 添加支出', 'delete': '删除', 'save': '保存',
        'cancel': '取消', 'settings': '设置', 'defaultFee': '默认金额:', 'currency': '货币:',
        'editPayment': '输入付款金额', 'paid': '已付:', 'waiting': '等待付款',
        'savedMsg': '数据已保存！', 'report': '月度报告',
        'fullName': '姓名', 'desc': '说明（例如：电费）', 'amount': '金额', 'date': '日期',
        'copyText': '复制文本', 'copiedMsg': '报告已复制！', 'saveDownloads': '保存到下载',
        'noExpense': '无支出记录。',
        'welcomeTitle': '欢迎使用财务追踪系统',
        'welcomeMsg': '轻松管理2006年至2050年的添加人员与收入、月度支出和结转余额，一键生成月度财务报告。',
        'startBtn': '进入账本',
      },
      '日本語': {
        'title': '2006-2050 出納管理', 'devir': '前月繰越:', 'gelir': '職員収入:',
        'gider': '支出:', 'net': '次月繰越:', 'tab1': '職員追加と収入', 'tab2': '支出',
        'addPerson': '+ 職員を追加', 'addExpense': '+ 支出を追加', 'delete': '削除', 'save': '保存',
        'cancel': 'キャンセル', 'settings': '設定', 'defaultFee': 'デフォルト金額:', 'currency': '通貨:',
        'editPayment': '支払金額を入力', 'paid': '支払済:', 'waiting': '支払い待ち',
        'savedMsg': '保存されました！', 'report': '月次レポート',
        'fullName': '氏名', 'desc': '内容（例：電気代）', 'amount': '金額', 'date': '日付',
        'copyText': 'テキストをコピー', 'copiedMsg': 'レポートをコピーしました！', 'saveDownloads': 'ダウンロードに保存',
        'noExpense': '記録された支出はありません。',
        'welcomeTitle': '出納管理へようこそ',
        'welcomeMsg': '2006年から2050年までの職員追加と収入、月次支出、繰越残高を簡単に管理し、ワンクリックで月次レポートを作成できます。',
        'startBtn': '出納帳を開く',
      },
      'Português': {
        'title': 'Controle de Caixa 2006-2050', 'devir': 'Saldo Anterior:', 'gelir': 'Receita Pessoal:',
        'gider': 'Despesas:', 'net': 'Próximo Saldo:', 'tab1': 'Adicionar Pessoal e Receitas', 'tab2': 'Despesas',
        'addPerson': '+ Adicionar Pessoal', 'addExpense': '+ Adicionar Despesa', 'delete': 'Excluir', 'save': 'Salvar',
        'cancel': 'Cancelar', 'settings': 'Configurações', 'defaultFee': 'Valor Padrão:', 'currency': 'Moeda:',
        'editPayment': 'Digite o valor', 'paid': 'Pago:', 'waiting': 'Aguardando pagamento',
        'savedMsg': 'Dados salvos!', 'report': 'Relatório Mensal',
        'fullName': 'Nome Completo', 'desc': 'Descrição (ex: Eletricidade)', 'amount': 'Valor', 'date': 'Data (DD.MM.AAAA)',
        'copyText': 'Copiar Texto', 'copiedMsg': 'Relatório copiado!', 'saveDownloads': 'Salvar em Downloads',
        'noExpense': 'Nenhuma despesa registrada.',
        'welcomeTitle': 'Bem-vindo ao Controle de Caixa',
        'welcomeMsg': 'Gerencie pessoal e receitas, despesas mensais e saldos acumulados de 2006 a 2050 com relatórios instantâneos.',
        'startBtn': 'Abrir Caixa',
      },
      'Italiano': {
        'title': 'Gestione Cassa 2006-2050', 'devir': 'Saldo Precedente:', 'gelir': 'Entrate Personale:',
        'gider': 'Spese:', 'net': 'Saldo Successivo:', 'tab1': 'Aggiungi Personale ed Entrate', 'tab2': 'Spese',
        'addPerson': '+ Aggiungi Personale', 'addExpense': '+ Aggiungi Spesa', 'delete': 'Elimina', 'save': 'Salva',
        'cancel': 'Annulla', 'settings': 'Impostazioni', 'defaultFee': 'Importo Predefinito:', 'currency': 'Valuta:',
        'editPayment': 'Inserisci importo', 'paid': 'Pagato:', 'waiting': 'In attesa',
        'savedMsg': 'Dati salvati!', 'report': 'Report Mensile',
        'fullName': 'Nome e Cognome', 'desc': 'Descrizione (es. Elettricità)', 'amount': 'Importo', 'date': 'Data (GG.MM.AAAA)',
        'copyText': 'Copia Testo', 'copiedMsg': 'Report copiato!', 'saveDownloads': 'Salva nei Download',
        'noExpense': 'Nessuna spesa registrata.',
        'welcomeTitle': 'Benvenuti in Gestione Cassa',
        'welcomeMsg': 'Gestisci facilmente personale ed entrate, spese mensili e saldi riportati dal 2006 al 2050 con report istantanei.',
        'startBtn': 'Apri Cassa',
      },
      'हिन्दी': {
        'title': '2006-2050 कैश ट्रैकिंग', 'devir': 'पिछला शेष:', 'gelir': 'कर्मचारी आय:',
        'gider': 'खर्च:', 'net': 'अगला शेष:', 'tab1': 'कर्मचारी जोड़ें और आय', 'tab2': 'खर्च',
        'addPerson': '+ कर्मचारी जोड़ें', 'addExpense': '+ खर्च जोड़ें', 'delete': 'हटाएं', 'save': 'सहेजें',
        'cancel': 'रद्द करें', 'settings': 'सेटिंग्स', 'defaultFee': 'डिफ़ॉल्ट राशि:', 'currency': 'मुद्रा:',
        'editPayment': 'भुगतान राशि दर्ज करें', 'paid': 'भुगतान किया:', 'waiting': 'भुगतान की प्रतीक्षा है',
        'savedMsg': 'डेटा सहेजा गया!', 'report': 'मासिक रिपोर्ट',
        'fullName': 'पूरा नाम', 'desc': 'विवरण (जैसे बिजली)', 'amount': 'राशि', 'date': 'तारीख',
        'copyText': 'टेक्स्ट कॉपी करें', 'copiedMsg': 'रिपोर्ट कॉपी की गई!', 'saveDownloads': 'डाउनलोड में सहेजें',
        'noExpense': 'कोई खर्च दर्ज नहीं है।',
        'welcomeTitle': 'कैश ट्रैकिंग में आपका स्वागत है',
        'welcomeMsg': '2006 से 2050 तक की कर्मचारी जोड़ें और आय, मासिक खर्च और शेष राशि को आसानी से प्रबंधित करें और तुरंत मासिक रिपोर्ट प्राप्त करें।',
        'startBtn': 'कैशबुक खोलें',
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
