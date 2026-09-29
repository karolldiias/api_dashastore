# 1. Estágio de Compilação
FROM dart:stable AS build

WORKDIR /app

# Ativa globalmente a ferramenta oficial do Dart Frog
RUN dart pub global activate dart_frog_cli

# Injeta a pasta de binários global no PATH do sistema operacional Linux
ENV PATH="${PATH}:/root/.pub-cache/bin"

# Copia as definições de pacotes do projeto
COPY pubspec.yaml ./
RUN dart pub get

# Copia todo o código-fonte local do projeto (routes/api/, lib/, etc.)
COPY . .

# 🌟 CORREÇÃO: Executa o construtor diretamente pelo caminho do sistema.
# Isso vai mapear e compilar as suas subpastas (/api/login, etc.) sem falhas no Docker.
RUN dart_frog build

# Compila o executável binário estático nativo de produção (AOT)
RUN dart compile exe build/bin/server.dart -o build/bin/server

# 2. Estágio de Execução (Gera a imagem de produção ultra leve)
FROM subfuzion/dart:slim

COPY --from=build /app/build/bin/server /app/bin/server
#COPY --from=build /app/public /app/public

EXPOSE 8080

CMD ["/app/bin/server"]
