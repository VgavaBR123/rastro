# Copia local do native_glass_navbar

Origem: pacote `native_glass_navbar` 1.2.0 do pub.dev
(https://github.com/TechSupportz/native_glass_navbar), licenca MIT (ver LICENSE).
Copiado sem `example/` e `test/`.

Mudanca do Rastro (unica):

- `TabBarActionButton.label` (opcional) vai para o lado nativo como `actionButtonLabel`
  e vira o `accessibilityLabel` do botao de acao. O pacote cria esse botao como o item
  de sistema `.search` (e o que da o botao circular separado no iOS 26), entao sem
  rotulo o VoiceOver anunciava "Buscar" no botao de gravar (achado INI-02 do teste no
  iPhone de 30/10/2026).

Ao atualizar o pacote: copiar a versao nova e reaplicar a mudanca acima (procure por
`actionButtonLabel`), ou voltar para o pub.dev se a versao nova ja aceitar o rotulo.
