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
    final user = body['user']?.toString().trim();

    if (user == null || user.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Usuário é obrigatório.',
        },
      );
    }

    // 1. Puxa todos os pedidos e relacionamentos em lote direto do Supabase
    final rawOrders = await OrderRepository.getByUserId(user);

    // 2. Transforma o resultado no padrão exato de chaves em CamelCase que seu front-end utiliza
    final userOrders = rawOrders.map((order) {
      final itemsList = (order['order_items'] as List?) ?? [];

      // Mapeia os itens do pedido limpando as chaves
      final parsedItems = itemsList.map((item) {
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
              'category': {'id': '', 'title': ''},
            };

        final categoryMap =
            productMap['category'] as Map<String, dynamic>? ??
            {
              'id': '',
              'title': '',
            };

        return {
          'id': orderItem['id'],
          'quantity': (orderItem['quantity'] as num?)?.toInt() ?? 0,
          'product': {
            'id': productMap['id'],
            'title': productMap['title'],
            'description': productMap['description'] ?? '',
            'price': double.tryParse(productMap['price'].toString()) ?? 0.0,
            'unit': productMap['unit'],
            'picture': productMap['picture'],
            'category': {
              'id': categoryMap['id'],
              'title': categoryMap['title'],
            },
          },
        };
      }).toList();

      return {
        'id': order['id'],
        'total': double.tryParse(order['total'].toString()) ?? 0.0,
        'createdAt': order['created_at'], // Alinhado com o banco postgresql
        'due': order['due'],
        'qrCodeImage': order['qr_code_image'],
        'copiaecola': order['copiaecola'],
        'status': order['status'],
        'items': parsedItems,
      };
    }).toList();

    return Response.json(
      body: {
        'result': userOrders,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao consultar pedidos.',
        'error': e.toString(),
      },
    );
  }
}
