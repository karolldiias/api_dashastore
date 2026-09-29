import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: 'Apenas método POST é permitido.',
    );
  }

  final headers = context.request.headers;
  final authorization =
      headers['Authorization'] ?? headers['authorization'] ?? '';

  // Validação do padrão 'Bearer <token>' no cabeçalho HTTP
  if (authorization.isEmpty || !authorization.startsWith('Bearer ')) {
    return Response.json(
      statusCode: 401,
      body: {
        'status': 'erro',
        'mensagem': 'Invalid session token.',
      },
    );
  }

  final token = authorization.substring(7).trim();

  // Executa a validação criptográfica integrada com o Supabase Auth
  final usuario = await UserRepository.validateSessionToken(token);

  if (usuario == null) {
    return Response.json(
      statusCode: 401,
      body: {
        'status': 'erro',
        'mensagem': 'Token inválido ou sessão expirada.',
      },
    );
  }

  // Devolve o mapa montado com a mesma estrutura exigida pelo seu aplicativo Flutter
  return Response.json(
    body: {
      'result': usuario,
    },
  );
}
