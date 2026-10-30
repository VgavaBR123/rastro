// Capitulos (F05): cor do tema para cada funcao de numero do capitulo.
library;

import '../../chapters/domain/chapter_pages.dart';
import '../theme/app_colors.dart';

RoleColors chapterRole(AppColors c, ChapterStat s) => switch (s.role) {
  ChapterStatRole.distance => c.dist,
  ChapterStatRole.time => c.tempo,
  ChapterStatRole.count => c.extra,
  ChapterStatRole.days => c.subida,
  ChapterStatRole.pace => c.pace,
  ChapterStatRole.sport => s.sport == null ? c.extra : c.sport(s.sport!),
  ChapterStatRole.streak => c.ciano,
  ChapterStatRole.joker => c.subida,
  ChapterStatRole.month => c.tempo,
};
