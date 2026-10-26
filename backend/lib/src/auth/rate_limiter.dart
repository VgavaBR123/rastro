// Limite de tentativas por chave (email, IP) em janela deslizante, em memoria.
// Puro: o relogio e injetado, entao os testes avancam o tempo sem esperar.
//
// Limitacao: o estado vive no processo. Com uma instancia so do servidor isso
// basta; com varias instancias (ou reinicios frequentes) cada uma teria o seu
// contador e o limite efetivo se multiplicaria. Nesse caso precisaria de um
// armazenamento compartilhado (ex.: tabela no Postgres ou Redis).
library;

class RateLimiter {
  RateLimiter({
    required this.maxAttempts,
    required this.window,
    required int Function() nowMs,
  })  : assert(maxAttempts > 0),
        _now = nowMs;

  /// Quantas tentativas registradas cabem na janela antes de bloquear.
  final int maxAttempts;

  /// Tamanho da janela deslizante.
  final Duration window;

  final int Function() _now;

  /// Instantes (ms) das tentativas registradas por chave, em ordem crescente.
  final Map<String, List<int>> _tentativas = {};

  /// Ultima varredura completa do mapa (poda das chaves esquecidas).
  int _ultimaVarredura = 0;

  /// Quantas chaves estao sendo acompanhadas (para testes e diagnostico).
  int get trackedKeys => _tentativas.length;

  /// null = liberado. Senao, quanto falta para a tentativa mais antiga que
  /// mantem o bloqueio sair da janela (sempre > 0).
  Duration? check(String key) {
    final List<int>? lista = _podar(key, _now());
    if (lista == null || lista.length < maxAttempts) return null;
    // Com n >= max registros, volta a liberar quando sobrarem max-1: ou seja,
    // quando o registro de indice n-max expirar.
    final int libera =
        lista[lista.length - maxAttempts] + window.inMilliseconds;
    return Duration(milliseconds: libera - _now());
  }

  /// Registra uma tentativa (falha de login, ou qualquer cadastro).
  void recordFailure(String key) {
    final int agora = _now();
    _varrerSePreciso(agora);
    (_tentativas[key] ??= <int>[]).add(agora);
  }

  /// Esquece a chave (ex.: login bem-sucedido daquele email).
  void reset(String key) => _tentativas.remove(key);

  /// Remove da chave os registros fora da janela; apaga a chave se esvaziar.
  List<int>? _podar(String key, int agora) {
    final List<int>? lista = _tentativas[key];
    if (lista == null) return null;
    final int corte = agora - window.inMilliseconds;
    var i = 0;
    while (i < lista.length && lista[i] <= corte) {
      i++;
    }
    if (i > 0) lista.removeRange(0, i);
    if (lista.isEmpty) {
      _tentativas.remove(key);
      return null;
    }
    return lista;
  }

  /// Poda todas as chaves no maximo uma vez por janela, na escrita. Assim
  /// chaves que nunca mais aparecem (emails e IPs de passagem) nao acumulam
  /// para sempre, e o custo fica amortizado.
  void _varrerSePreciso(int agora) {
    if (agora - _ultimaVarredura < window.inMilliseconds) return;
    _ultimaVarredura = agora;
    for (final String k in _tentativas.keys.toList()) {
      _podar(k, agora);
    }
  }
}

/// Segundos inteiros para o header Retry-After: arredonda para cima, minimo 1.
int retryAfterSeconds(Duration d) {
  final int s = (d.inMilliseconds + 999) ~/ 1000;
  return s < 1 ? 1 : s;
}
