/// Quem pode ver uma atividade (tela Salvar). Guardado como texto na coluna
/// `activities.visibility`, para o banco nao depender da ordem do enum.
library;

enum ActivityVisibility {
  onlyMe('private'),
  followers('followers'),
  everyone('everyone');

  const ActivityVisibility(this.dbValue);

  /// Valor gravado no banco.
  final String dbValue;

  /// Le o valor do banco; desconhecido ou null vira [everyone] (o padrao).
  static ActivityVisibility fromDb(String? value) {
    for (final v in values) {
      if (v.dbValue == value) return v;
    }
    return everyone;
  }
}
