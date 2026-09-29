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
    final body = await context.request.json() as Map<String, dynamic>;

    final email = body['email']?.toString().trim();
    final currentPassword = body['currentPassword']?.toString();
    final newPassword = body['newPassword']?.toString();

    if (email == null ||
        email.isEmpty ||
        currentPassword == null ||
        currentPassword.isEmpty ||
        newPassword == null ||
        newPassword.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'message': 'Todos os campos são obrigatórios.'},
      );
    }

    final usuario = await UserRepository.getByEmail(email);

    if (usuario == null) {
      return Response.json(
        statusCode: 404,
        body: {'message': 'Usuário não encontrado.'},
      );
    }

    try {
      // Executa a alteração na nuvem
      await UserRepository.updatePassword(
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (authError) {
      final errorMsg = authError.toString();
      if (errorMsg.contains('Invalid login credentials') ||
          errorMsg.contains('invalid_credentials')) {
        return Response.json(
          statusCode: 400,
          body: {'message': 'Senha atual inválida.'},
        );
      }
      rethrow;
    }

    return Response.json(
      body: {
        'success': true,
        // ignore: inference_failure_on_collection_literal
        'result': [],
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'message': 'Erro ao alterar senha.',
        'error': e.toString(),
      },
    );
  }
}
