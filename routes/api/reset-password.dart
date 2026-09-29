import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/user_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: 'Apenas método POST é permitido.',
    );
  }

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final email = data['email']?.toString().trim() ?? '';

    if (email.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'O campo e-mail é obrigatório.',
        },
      );
    }

    // 1. Verifica de forma assíncrona se o usuário existe no Supabase
    final usuario = await UserRepository.getByEmail(email);

    if (usuario == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'error': 'Nenhum usuário encontrado com este e-mail.',
        },
      );
    }

    // 2. Dispara o fluxo real de recuperação de e-mail do Supabase
    await UserRepository.sendPasswordResetEmail(email);

    // 3. Retorna a resposta de sucesso mantendo compatibilidade com seu front-end
    return Response.json(
      body: {
        'result': {
          'status': 'sucesso',
          'mensagem':
              'Um link de redefinição foi enviado com segurança para o seu e-mail.',
          'email': email,
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'error': e.toString(),
      },
    );
  }
}
