# 1. Estágio de Compilação
FROM dart:stable AS build

WORKDIR /app

# Ativa globalmente a CLI do Dart Frog e configura o PATH do sistema Linux
RUN dart pub global activate dart_frog_cli
ENV PATH="${PATH}:/root/.pub-cache/bin"

# Copia as dependências e executa o pub get
COPY pubspec.yaml ./
RUN dart pub get

# Copia todo o código-fonte (routes, lib, database, etc.)
COPY . .

# 🌟 O SEGREDO PARA SUBPASTAS: Garante que os arquivos gerados herdem 
# o mapeamento limpo de rotas internas antes da compilação nativa
RUN dart pub global run dart_frog_cli build

# Compila o executável nativo AOT de produção estável
RUN dart compile exe build/bin/server.dart -o build/bin/server

# 2. Estágio de Execução (Gera a imagem de produção ultra leve)
FROM subfuzion/dart:slim

COPY --from=build /app/build/bin/server /app/bin/server
COPY --from=build /app/public /app/public

EXPOSE 8080

CMD ["/app/bin/server"]
