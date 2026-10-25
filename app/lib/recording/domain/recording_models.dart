/// Enums de dominio da gravacao. Clean room a partir de relatorios/03 e 05.

library;

/// Estado da gravacao (etapa 03).
enum RecordingState { idle, recording, autoPaused, manuallyPaused, finished }

/// Tipo de pausa (etapa 03/05): distingue auto de manual.
enum PauseType { auto, manual }

/// Tipo de atividade. Comecamos pelos tres do objetivo (CLAUDE.md).
enum ActivityType { run, ride, walk }

/// Estagio de sincronizacao do registro (etapa 05/06).
enum SyncState { recording, pending, uploading, synced, failed }
