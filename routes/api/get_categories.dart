import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/category_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  // 1. Permite a requisição preflight de OPTIONS (CORS) se houver
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  // 2. Bloqueia qualquer método que não seja GET, pois estamos apenas recuperando dados
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: 405,
      body: 'Apenas o método GET é permitido neste endpoint de listagem.',
    );
  }

  try {
    // 3. Executa a busca no repositório utilizando o await correto
    final categorias = await CategoryRepository.getAll();

    // 4. Retorna a lista de categorias recuperadas do Supabase
    return Response.json(
      body: {
        'success': true,
        'message': 'Categorias recuperadas com sucesso!',
        'total': categorias.length,
        'result': categorias,
      },
    );
  } catch (e) {
    // Retorna erro amigável se a requisição ao Supabase falhar
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao consultar categorias populadas.',
        'error': e.toString(),
      },
    );
  }
}
