/// CSV (RFC 4180) para o activities.csv da exportacao de conta e para o
/// atividades.csv que exportamos. Dart puro.
library;

/// Linhas e campos de [text]. Aceita aspas com virgula, aspas duplicadas e
/// quebra de linha dentro do campo, CRLF e BOM. Linhas vazias sao puladas.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  if (text.startsWith('﻿')) i = 1;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.single.isEmpty)) rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
      } else {
        field.write(ch);
      }
      i++;
      continue;
    }
    switch (ch) {
      case '"':
        inQuotes = true;
      case ',':
        endField();
      case '\r':
        if (i + 1 < text.length && text[i + 1] == '\n') i++;
        endRow();
      case '\n':
        endRow();
      default:
        field.write(ch);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

final RegExp _needsQuotes = RegExp('[",\r\n]');

/// Campo pronto para o CSV. Texto que comeca com = + - @ tab ou CR ganha um
/// apostrofo na frente, para a planilha nao executar como formula.
String csvField(String value) {
  var v = value;
  if (v.isNotEmpty && '=+-@\t\r'.contains(v[0])) v = "'$v";
  if (!_needsQuotes.hasMatch(v)) return v;
  return '"${v.replaceAll('"', '""')}"';
}
