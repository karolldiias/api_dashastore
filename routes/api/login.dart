import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: 'Apenas método POST é permitido.',
    );
  }

  try {
    final body = await context.request.body();
    final credentials = jsonDecode(body) as Map<String, dynamic>;

    final email = credentials['email']?.toString() ?? '';
    final password = credentials['password']?.toString() ?? '';

    // Validação inicial de campos nulos/vazios
    if (email.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'status': 'erro',
          'mensagem': 'EMAIL_E_SENHA_OBRIGATORIOS',
        },
      );
    }

    // Executa a autenticação integrada com o Supabase
    final usuarioAutenticado = await UserRepository.signIn(
      email: email,
      password: password,
    );

    // Retorna a estrutura idêntica à que o seu front-end já esperava
    return Response.json(
      body: {
        'result': usuarioAutenticado,
      },
    );
  } catch (e) {
    // Trata erros de login inválido lançados pelo Supabase
    final erroMensagem = e.toString();

    if (erroMensagem.contains('Invalid login credentials') ||
        erroMensagem.contains('invalid_credentials')) {
      return Response.json(
        statusCode: 401,
        body: {
          'status': 'erro',
          'mensagem': 'INVALID_CREDENTIALS',
        },
      );
    }

    return Response.json(
      statusCode: 500,
      body: {
        'status': 'erro',
        'mensagem': erroMensagem,
      },
    );
  }
}
