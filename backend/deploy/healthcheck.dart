// Verificador de saude usado pelo HEALTHCHECK do container.
// A imagem final e "scratch" (sem shell, curl ou wget), entao este programa
// minimo e compilado junto com o servidor. Faz GET em /health na porta local
// (PORT, padrao 8080) e sai com 0 se a resposta for 200, 1 caso contrario.
// So usa dart:io: nao depende de nenhum pacote.
import 'dart:io';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final req = await client
        .getUrl(Uri.parse('http://127.0.0.1:$port/health'))
        .timeout(const Duration(seconds: 3));
    final res = await req.close().timeout(const Duration(seconds: 3));
    await res.drain<void>();
    exitCode = res.statusCode == 200 ? 0 : 1;
  } catch (_) {
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}
