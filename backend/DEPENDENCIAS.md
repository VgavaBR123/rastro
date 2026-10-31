# Dependencias do backend

Dependencias diretas do `pubspec.yaml` e o motivo de cada uma. Antes de
acrescentar outra, registrar aqui (nome, versao, licenca, para que serve).

| Pacote | Versao resolvida | Licenca | Para que |
| --- | --- | --- | --- |
| shelf | ^1.4.0 | BSD-3-Clause | servidor HTTP |
| shelf_router | ^1.1.0 | BSD-3-Clause | rotas |
| postgres | ^3.4.0 | BSD-3-Clause | PostgreSQL/PostGIS |
| crypto | 3.0.8 | BSD-3-Clause | sha256 dos tokens de sessao |
| mailer | 7.2.0 | MIT | email da recuperacao de senha (SMTP) |
| googleapis_auth | 2.3.5 | BSD-3-Clause | F08: JWT da conta de servico do Firebase e token OAuth2 para o FCM HTTP v1 (so com `FIREBASE_SERVICE_ACCOUNT`) |
| http | 1.6.0 | BSD-3-Clause | F08: cliente HTTP do `FcmPushSender` (e `MockClient` nos testes) |

Transitivas novas trazidas pelo `googleapis_auth` (F08): `google_cloud` 0.5.0
(Apache-2.0), `google_identity_services_web` 0.3.3+1 (BSD-3-Clause, so usado no
alvo web, nao no servidor), `web` 1.1.2 (BSD-3-Clause).
