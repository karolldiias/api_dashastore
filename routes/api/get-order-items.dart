import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/order_repository.dart';

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
    final orderId = body['orderId']?.toString().trim();

    if (orderId == null || orderId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'orderId é obrigatório.',
        },
      );
    }

    // 1. Busca o pedido completo com seus itens e sub-relacionamentos de produtos na nuvem
    final order = await OrderRepository.getById(orderId);

    if (order == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Pedido não encontrado.',
        },
      );
    }

    // 2. Extrai a lista de itens vinculados retornada pelo Supabase
    final itemsList = (order['order_items'] as List?) ?? [];

    // 3. Mapeia de forma puramente síncrona mantendo a exata estrutura de chaves exigida pelo front-end
    final result = itemsList.map((item) {
      final orderItem = item as Map<String, dynamic>;
      final productMap =
          orderItem['products'] as Map<String, dynamic>? ??
          {
            'id': 'unknown',
            'title': 'Produto não encontrado',
            'description': '',
            'price': 0.0,
            'unit': 'un',
            'picture': '',
            'category': {
              'id': '',
              'title': '',
            },
          };

      final categoryMap =
          productMap['category'] as Map<String, dynamic>? ??
          {
            'id': '',
            'title': '',
          };

      final quantity = (orderItem['quantity'] as num?)?.toInt() ?? 0;
      final price = double.tryParse(productMap['price'].toString()) ?? 0.0;

      return {
        'id': orderItem['id']?.toString() ?? '${orderId}_${productMap['id']}',
        'quantity': quantity,
        'product': {
          'id': productMap['id'],
          'title': productMap['title'],
          'description': productMap['description'] ?? '',
          'price': price,
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
        'result': result,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao consultar itens do pedido.',
        'error': e.toString(),
      },
    );
  }
}
