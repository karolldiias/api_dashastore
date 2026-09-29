# 1. Fase de Compilação
FROM dart:stable AS build

WORKDIR /app

# Copia as configurações de pacotes
COPY pubspec.yaml ./
RUN dart pub get

# Copia todo o código fonte do seu projeto
COPY . .

# Em vez de chamar a CLI externa, nós compilamos direto o ponto de entrada gerado
# Isso evita o erro 66 de varredura de rotas do container Linux
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli build

# Compila o executável AOT de produção nativo
RUN dart compile exe build/bin/server.dart -o build/bin/server

# 2. Fase de Execução (Gera uma imagem super leve de apenas ~20MB)
FROM subfuzion/dart:slim

COPY --from=build /app/build/bin/server /app/bin/server
COPY --from=build /app/public /app/public

EXPOSE 8080

CMD ["/app/bin/server"]
