/// Utilitarios dos leitores GPX e TCX: parse defensivo e busca por nome local
/// (ignora prefixo e namespace, que variam entre aparelhos). Dart puro.
library;

import 'package:xml/xml.dart';

import 'import_models.dart';

/// Documento XML de [text], ou [ImportFormatException] com motivo curto.
XmlDocument parseXmlDocument(String text) {
  if (text.trim().isEmpty) throw const ImportFormatException('arquivo vazio');
  try {
    return XmlDocument.parse(text);
  } on XmlException {
    throw const ImportFormatException('XML mal formado');
  }
}

/// Filhos diretos de [e] com nome local [name].
Iterable<XmlElement> childrenNamed(XmlElement e, String name) =>
    e.childElements.where((c) => c.name.local == name);

/// Primeiro filho direto com nome local [name], ou null.
XmlElement? childNamed(XmlElement e, String name) {
  for (final c in e.childElements) {
    if (c.name.local == name) return c;
  }
  return null;
}

/// Texto (sem espacos nas pontas) do filho [name]; null se nao existe ou vazio.
String? childText(XmlElement e, String name) {
  final t = childNamed(e, name)?.innerText.trim();
  return t == null || t.isEmpty ? null : t;
}

/// Descendentes com nome local [name], em ordem de documento.
Iterable<XmlElement> descendantsNamed(XmlNode e, String name) =>
    e.findAllElements(name, namespace: '*');

double? parseDouble(String? s) {
  if (s == null) return null;
  final v = double.tryParse(s.trim());
  return v != null && v.isFinite ? v : null;
}
