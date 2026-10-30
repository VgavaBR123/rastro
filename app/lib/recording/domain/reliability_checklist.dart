/// Checklist "Gravacao confiavel" (F01). A partir do estado real do aparelho
/// (lido pela borda de plataforma), monta os itens que a tela mostra, com o
/// estado de cada um e a acao que resolve. Inclui instrucoes por fabricante
/// para os celulares que encerram apps em segundo plano. Dart puro.
library;

enum DevicePlatform { android, ios, other }

/// Acesso a localizacao concedido ao app.
enum LocationAccess { unknown, denied, deniedForever, whileInUse, always }

/// Fabricantes com instrucoes proprias (as marcas comuns no Brasil).
enum Manufacturer { xiaomi, samsung, motorola, generic }

/// Estado real lido do aparelho. Null = nao deu para ler (ou nao se aplica).
class ReliabilitySnapshot {
  final DevicePlatform platform;
  final String? manufacturer;
  final bool? batteryOptimizationIgnored;
  final LocationAccess location;
  final bool? preciseLocation;
  final bool? notificationsGranted;

  const ReliabilitySnapshot({
    required this.platform,
    this.manufacturer,
    this.batteryOptimizationIgnored,
    this.location = LocationAccess.unknown,
    this.preciseLocation,
    this.notificationsGranted,
  });

  static const Object _keep = Object();

  ReliabilitySnapshot copyWith({
    Object? manufacturer = _keep,
    Object? batteryOptimizationIgnored = _keep,
    LocationAccess? location,
    Object? preciseLocation = _keep,
    Object? notificationsGranted = _keep,
  }) => ReliabilitySnapshot(
    platform: platform,
    manufacturer: identical(manufacturer, _keep)
        ? this.manufacturer
        : manufacturer as String?,
    batteryOptimizationIgnored: identical(batteryOptimizationIgnored, _keep)
        ? this.batteryOptimizationIgnored
        : batteryOptimizationIgnored as bool?,
    location: location ?? this.location,
    preciseLocation: identical(preciseLocation, _keep)
        ? this.preciseLocation
        : preciseLocation as bool?,
    notificationsGranted: identical(notificationsGranted, _keep)
        ? this.notificationsGranted
        : notificationsGranted as bool?,
  );
}

enum ChecklistItemId {
  battery,
  location,
  preciseLocation,
  notifications,
  manufacturer,
}

enum ChecklistStatus {
  /// Configurado.
  ok,

  /// Funciona, mas da para melhorar.
  warning,

  /// Precisa de ajuste para a gravacao nao ser interrompida.
  action,

  /// Nao deu para conferir neste aparelho.
  unknown,

  /// So orientacao (passos do fabricante), sem como conferir.
  info,
}

/// O que o botao do item faz.
enum ChecklistAction {
  none,
  openBatterySettings,
  requestLocation,
  openAppSettings,
  requestNotifications,
  openManufacturerSettings,
}

class ChecklistItem {
  final ChecklistItemId id;
  final String title;
  final String description;
  final ChecklistStatus status;
  final ChecklistAction action;

  /// Rotulo do botao da acao.
  final String? actionLabel;

  /// Passos manuais (instrucoes por fabricante).
  final List<String> steps;

  const ChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.action = ChecklistAction.none,
    this.actionLabel,
    this.steps = const [],
  });
}

/// Tela de ajuste de um fabricante (componente Android explicito).
class ManufacturerShortcut {
  final String packageName;
  final String className;
  const ManufacturerShortcut(this.packageName, this.className);
}

class ManufacturerGuide {
  final Manufacturer manufacturer;
  final String name;
  final List<String> steps;

  /// Telas tentadas em ordem; sem nenhuma, abre os detalhes do app.
  final List<ManufacturerShortcut> shortcuts;

  const ManufacturerGuide({
    required this.manufacturer,
    required this.name,
    required this.steps,
    this.shortcuts = const [],
  });
}

Manufacturer detectManufacturer(String? raw) {
  final m = raw?.trim().toLowerCase() ?? '';
  if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) {
    return Manufacturer.xiaomi;
  }
  if (m.contains('samsung')) return Manufacturer.samsung;
  if (m.contains('motorola') || m == 'moto') return Manufacturer.motorola;
  return Manufacturer.generic;
}

ManufacturerGuide manufacturerGuide(Manufacturer m) => switch (m) {
  Manufacturer.xiaomi => const ManufacturerGuide(
    manufacturer: Manufacturer.xiaomi,
    name: 'Xiaomi',
    steps: [
      'Em Inicio automatico, ligue o Rastro.',
      'Em Economia de bateria do app, escolha Sem restricoes.',
      'Nos apps recentes, segure o Rastro e toque no cadeado para fixa-lo.',
    ],
    shortcuts: [
      ManufacturerShortcut(
        'com.miui.securitycenter',
        'com.miui.permcenter.autostart.AutoStartManagementActivity',
      ),
    ],
  ),
  Manufacturer.samsung => const ManufacturerGuide(
    manufacturer: Manufacturer.samsung,
    name: 'Samsung',
    steps: [
      'Em Bateria, abra Limites de uso em segundo plano.',
      'Tire o Rastro de Apps em suspensao e Apps em suspensao profunda.',
      'Adicione o Rastro em Apps que nunca entram em suspensao.',
    ],
    shortcuts: [
      ManufacturerShortcut(
        'com.samsung.android.lool',
        'com.samsung.android.sm.battery.ui.BatteryActivity',
      ),
      ManufacturerShortcut(
        'com.samsung.android.sm',
        'com.samsung.android.sm.ui.battery.BatteryActivity',
      ),
    ],
  ),
  Manufacturer.motorola => const ManufacturerGuide(
    manufacturer: Manufacturer.motorola,
    name: 'Motorola',
    steps: [
      'Em Configuracoes > Apps > Rastro > Bateria, escolha Sem restricoes.',
      'Desative a Bateria adaptavel se a gravacao parar com a tela desligada.',
    ],
  ),
  Manufacturer.generic => const ManufacturerGuide(
    manufacturer: Manufacturer.generic,
    name: 'Android',
    steps: [
      'Em Configuracoes > Apps > Rastro > Bateria, escolha Sem restricoes.',
      'Nao feche o Rastro pelos apps recentes durante a gravacao.',
    ],
  ),
};

/// Itens na ordem da tela. No iOS so os que se aplicam (localizacao).
List<ChecklistItem> buildReliabilityChecklist(ReliabilitySnapshot s) {
  final android = s.platform == DevicePlatform.android;
  final ios = s.platform == DevicePlatform.ios;
  return [
    if (android) _battery(s.batteryOptimizationIgnored),
    _location(s.location, ios: ios),
    _precise(s.preciseLocation),
    if (android) _notifications(s.notificationsGranted),
    if (android) _manufacturer(detectManufacturer(s.manufacturer)),
  ];
}

/// Pronto para gravar: nenhum item exige acao.
bool isReliabilityReady(List<ChecklistItem> items) =>
    items.every((i) => i.status != ChecklistStatus.action);

ChecklistItem _battery(bool? ignored) => ChecklistItem(
  id: ChecklistItemId.battery,
  title: 'Sem otimizacao de bateria',
  description: switch (ignored) {
    true => 'O sistema nao vai pausar o Rastro para economizar bateria.',
    false =>
      'O sistema pode encerrar a gravacao com a tela desligada. Tire o Rastro '
          'da otimizacao de bateria.',
    null => 'Nao foi possivel conferir neste aparelho.',
  },
  status: switch (ignored) {
    true => ChecklistStatus.ok,
    false => ChecklistStatus.action,
    null => ChecklistStatus.unknown,
  },
  action: ignored == true
      ? ChecklistAction.none
      : ChecklistAction.openBatterySettings,
  actionLabel: ignored == true ? null : 'Abrir ajuste de bateria',
);

ChecklistItem _location(LocationAccess a, {required bool ios}) {
  final (
    ChecklistStatus status,
    String text,
    ChecklistAction action,
  ) = switch (a) {
    LocationAccess.always => (
      ChecklistStatus.ok,
      'Permitida sempre: a gravacao continua com a tela bloqueada.',
      ChecklistAction.none,
    ),
    LocationAccess.whileInUse when ios => (
      ChecklistStatus.warning,
      'Permitida durante o uso. Para gravar com mais seguranca com a tela '
          'bloqueada, escolha Sempre nos ajustes do app.',
      ChecklistAction.openAppSettings,
    ),
    LocationAccess.whileInUse => (
      ChecklistStatus.ok,
      'Permitida durante o uso. A notificacao da gravacao mantem o GPS '
          'ligado com a tela desligada.',
      ChecklistAction.none,
    ),
    LocationAccess.denied => (
      ChecklistStatus.action,
      'Sem permissao o Rastro nao consegue gravar o trajeto.',
      ChecklistAction.requestLocation,
    ),
    LocationAccess.deniedForever => (
      ChecklistStatus.action,
      'A permissao foi negada. Libere a localizacao nos ajustes do app.',
      ChecklistAction.openAppSettings,
    ),
    LocationAccess.unknown => (
      ChecklistStatus.unknown,
      'Nao foi possivel conferir neste aparelho.',
      ChecklistAction.none,
    ),
  };
  return ChecklistItem(
    id: ChecklistItemId.location,
    title: 'Permissao de localizacao',
    description: text,
    status: status,
    action: action,
    actionLabel: switch (action) {
      ChecklistAction.requestLocation => 'Permitir localizacao',
      ChecklistAction.openAppSettings => 'Abrir ajustes do app',
      _ => null,
    },
  );
}

ChecklistItem _precise(bool? precise) => ChecklistItem(
  id: ChecklistItemId.preciseLocation,
  title: 'Localizacao precisa',
  description: switch (precise) {
    true => 'O GPS entrega a posicao exata.',
    false =>
      'Com a localizacao aproximada a distancia e o pace ficam errados. Ligue '
          'Localizacao precisa nos ajustes do app.',
    null => 'Nao foi possivel conferir neste aparelho.',
  },
  status: switch (precise) {
    true => ChecklistStatus.ok,
    false => ChecklistStatus.action,
    null => ChecklistStatus.unknown,
  },
  action: precise == false
      ? ChecklistAction.openAppSettings
      : ChecklistAction.none,
  actionLabel: precise == false ? 'Abrir ajustes do app' : null,
);

ChecklistItem _notifications(bool? granted) => ChecklistItem(
  id: ChecklistItemId.notifications,
  title: 'Notificacoes',
  description: switch (granted) {
    true => 'A notificacao da gravacao aparece com os controles e os avisos.',
    false =>
      'Sem notificacao voce nao ve os controles nem os avisos de lacuna.',
    null => 'Nao foi possivel conferir neste aparelho.',
  },
  status: switch (granted) {
    true => ChecklistStatus.ok,
    false => ChecklistStatus.action,
    null => ChecklistStatus.unknown,
  },
  action: granted == true
      ? ChecklistAction.none
      : ChecklistAction.requestNotifications,
  actionLabel: granted == true ? null : 'Permitir notificacoes',
);

ChecklistItem _manufacturer(Manufacturer m) {
  final g = manufacturerGuide(m);
  return ChecklistItem(
    id: ChecklistItemId.manufacturer,
    title: m == Manufacturer.generic
        ? 'Ajustes do Android'
        : 'Ajustes do ${g.name}',
    description: 'O sistema nao informa estes ajustes; confira a mao.',
    status: ChecklistStatus.info,
    action: ChecklistAction.openManufacturerSettings,
    actionLabel: g.shortcuts.isEmpty
        ? 'Abrir ajustes do app'
        : 'Abrir ajuste do ${g.name}',
    steps: g.steps,
  );
}
