/// Utilitarios dos leitores GPX e TCX (F07). Leitura por EVENTOS do
/// package:xml (sem montar a arvore DOM): um arquivo grande nao vira
/// gigabytes de nos na memoria; so guardamos o que interessa. Nomes
/// comparados pelo nome local (sem prefixo), que varia entre aparelhos.
/// Dart puro.
library;

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import 'import_models.dart';

/// Nome local de um nome qualificado ("ns3:TPX" -> "TPX").
String localName(String qualified) {
  final i = qualified.indexOf(':');
  return i < 0 ? qualified : qualified.substring(i + 1);
}

/// Percorre os eventos de [text] chamando [onStart], [onText] e [onEnd]
/// com a pilha de nomes locais ja atualizada (no inicio, o elemento novo
/// esta no topo; no fim, ainda esta). Elemento auto-fechado gera inicio e
/// fim. XML mal formado vira [ImportFormatException].
void walkXml(
  String text, {
  required void Function(List<String> stack, Map<String, String> attributes) onStart,
  required void Function(List<String> stack, String text) onText,
  required void Function(List<String> stack) onEnd,
}) {
  if (text.trim().isEmpty) throw const ImportFormatException('arquivo vazio');
  final stack = <String>[];
  var sawRoot = false;
  try {
    for (final e in parseEvents(text, validateNesting: true, validateDocument: true)) {
      switch (e) {
        case XmlStartElementEvent():
          sawRoot = true;
          stack.add(localName(e.name));
          onStart(stack, {for (final a in e.attributes) localName(a.name): a.value});
          if (e.isSelfClosing) {
            onEnd(stack);
            stack.removeLast();
          }
        case XmlEndElementEvent():
          onEnd(stack);
          if (stack.isNotEmpty) stack.removeLast();
        case XmlTextEvent():
          if (stack.isNotEmpty) onText(stack, e.value);
        case XmlCDATAEvent():
          if (stack.isNotEmpty) onText(stack, e.value);
        default:
          break;
      }
    }
  } on XmlException {
    throw const ImportFormatException('XML mal formado');
  }
  if (!sawRoot || stack.isNotEmpty) throw const ImportFormatException('XML mal formado');
}

/// Pai do elemento no topo da pilha (ou '').
String parentOf(List<String> stack) => stack.length >= 2 ? stack[stack.length - 2] : '';

double? parseDouble(String? s) {
  if (s == null) return null;
  final v = double.tryParse(s.trim());
  return v != null && v.isFinite ? v : null;
}

String? cleanText(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}
