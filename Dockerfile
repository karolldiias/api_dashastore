# Imagem oficial estável do Dart
FROM dart:stable AS build

WORKDIR /app

# Copia as dependências e executa o pub get
COPY pubspec.yaml ./
RUN dart pub get

# Copia todo o código fonte para dentro do container
COPY . .

# Ativa a CLI do Dart Frog e compila o projeto em lote na nuvem
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli build

# Compila o binário nativo de produção (AOT)
RUN dart compile exe build/bin/server.dart -o build/bin/server

# Cria uma imagem enxuta e super leve para rodar o servidor
FROM subfuzion/dart:slim

COPY --from=build /app/build/bin/server /app/bin/server
COPY --from=build /app/public /app/public

# Expõe a porta padrão do servidor
EXPOSE 8080

CMD ["/app/bin/server"]
