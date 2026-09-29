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
    final data = jsonDecode(body) as Map<String, dynamic>;

    final fullname = data['fullname']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final cpf = data['cpf']?.toString() ?? '';
    final password = data['password']?.toString() ?? '';

    if (fullname.isEmpty || email.isEmpty || password.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'status': 'erro',
          'mensagem': 'INVALID_CREDENTIALS_USER',
        },
      );
    }

    final usuarioExistente = await UserRepository.getByEmail(email);

    if (usuarioExistente != null) {
      return Response.json(
        statusCode: 400,
        body: {
          'status': 'erro',
          'mensagem': 'Este e-mail já está cadastrado.',
        },
      );
    }

    // Executa o cadastro com login automático integrado
    final resultado = await UserRepository.signUp(
      fullname: fullname,
      email: email,
      phone: phone,
      cpf: cpf,
      password: password,
    );

    return Response.json(
      statusCode: 201,
      body: {
        'result': {
          'id': resultado['id'],
          'fullname': resultado['fullname'],
          'email': resultado['email'],
          'phone': resultado['phone'],
          'cpf': resultado['cpf'],
          'password': resultado['password'],
          'token':
              resultado['token'], // Agora este token é um JWT real do Supabase
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'status': 'erro',
        'mensagem': e.toString(),
      },
    );
  }
}
