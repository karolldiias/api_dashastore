import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/category_repository.dart';

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
    final categorias = await CategoryRepository.getAll();

    return Response.json(
      body: {
        'result': categorias,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao consultar categorias.',
        'error': e.toString(),
      },
    );
  }
}
