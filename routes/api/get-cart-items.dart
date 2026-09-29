import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/cart_repository.dart';

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
    final user = body['user']?.toString();

    if (user == null || user.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'O campo "user" (ID do usuário) é obrigatório.',
        },
      );
    }

    // 1. Busca os itens do carrinho do usuário específico de forma assíncrona
    final itensDoCarrinho = await CartRepository.getAll(user);

    // 2. Mapeia síncronamente os dados mantendo a exata estrutura esperada pelo Flutter
    final resultadoFinal = itensDoCarrinho.map((itemCarrinho) {
      final productMap =
          itemCarrinho['product'] as Map<String, dynamic>? ??
          {
            'id': 'unknown',
            'title': 'Produto não encontrado',
            'description': '',
            'price': 0.0,
            'unit': 'un',
            'picture': '',
            'category': {
              'id': 'unknown',
              'title': 'Sem categoria',
            },
          };

      final categoryMap =
          productMap['category'] as Map<String, dynamic>? ??
          {
            'id': 'unknown',
            'title': 'Sem categoria',
          };

      return {
        'id': itemCarrinho['id'],
        'quantity': itemCarrinho['quantity'],
        'product': {
          'id': productMap['id'],
          'title': productMap['title'],
          'description': productMap['description'] ?? '',
          'price': productMap['price'],
          'unit': productMap['unit'],
          'picture': productMap['picture'],
          'category': {
            'id': categoryMap['id'],
            'title': categoryMap['title'],
          },
        },
      };
    }).toList();

    return Response.json(
      body: {
        'result': resultadoFinal,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao consultar carrinho.',
        'error': e.toString(),
      },
    );
  }
}
