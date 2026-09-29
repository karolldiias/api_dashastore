# 1. Fase de Compilação - Usa a pasta build pré-gerada no seu Windows
FROM dart:stable AS build

WORKDIR /app

# Copia os arquivos de configuração de pacotes
COPY pubspec.yaml ./
RUN dart pub get

# Copia todo o código fonte (incluindo a pasta build gerada pelo seu Windows)
COPY . .

# 🌟 O SEGREDO: Como a pasta 'build' já foi gerada na sua máquina, 
# nós NÃO precisamos rodar o comando 'dart_frog_cli build' na nuvem! 
# Nós compilamos direto o ponto de entrada estático estável.
RUN dart compile exe build/bin/server.dart -o build/bin/server

# 2. Fase de Execução - Imagem de Produção Super Leve
FROM subfuzion/dart:slim

COPY --from=build /app/build/bin/server /app/bin/server
COPY --from=build /app/public /app/public

EXPOSE 8080

CMD ["/app/bin/server"]
