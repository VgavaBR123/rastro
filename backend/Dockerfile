# Imagem de producao da API (Dart/shelf).
#
# Estagio 1: compila o servidor em executavel nativo (AOT) com a imagem oficial
# do Dart. Versao fixada: o pubspec.lock exige Dart >= 3.13.
# Estagio 2: "scratch" com so o runtime minimo que a imagem dart ja separa em
# /runtime (libc, resolvedor DNS, certificados CA) + os dois executaveis.
# Padrao descrito na documentacao da imagem oficial "dart" no Docker Hub.
#
# Build:  docker build -t rastro-api .
# Precisa de pubspec.lock no contexto (pub get --enforce-lockfile).

FROM dart:3.13.7 AS build
WORKDIR /app

# Dependencias primeiro: camada reaproveitada enquanto pubspec nao muda.
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile

# Codigo (o .dockerignore deixa de fora testes, docs, .dart_tool etc.).
COPY . .
RUN dart pub get --offline --enforce-lockfile \
 && mkdir -p /out \
 && dart compile exe bin/server.dart -o /out/server \
 && dart compile exe deploy/healthcheck.dart -o /out/healthcheck

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /out/server /out/healthcheck /app/bin/

# Usuario sem privilegios (numerico: scratch nao tem /etc/passwd).
USER 65532:65532

# Porta interna fixa; o mapeamento para o host fica no docker-compose.
ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
  CMD ["/app/bin/healthcheck"]

ENTRYPOINT ["/app/bin/server"]
