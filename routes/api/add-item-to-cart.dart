import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/cart_repository.dart';
import 'package:api_dashastore_cupcake/repositories/product_repository.dart';

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

    // O campo 'user' aqui deve conter o id (UUID) do usuário logado vindo do front-end
    final user = body['user']?.toString();
    final productId = body['productId']?.toString();
    final quantity = int.tryParse(body['quantity']?.toString() ?? '');

    if (user == null || user.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Usuário é obrigatório.',
        },
      );
    }

    if (productId == null || productId.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'ProductId é obrigatório.',
        },
      );
    }

    if (quantity == null || quantity <= 0) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Quantidade inválida.',
        },
      );
    }

    // Valida se o produto realmente existe no Supabase antes de adicionar ao carrinho
    final produto = await ProductRepository.getById(productId);

    if (produto == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Produto não encontrado.',
        },
      );
    }

    // O método add agora lida nativamente com a verificação de duplicidade e soma no Supabase
    // ... validações do endpoint anteriores ...

    // O método add agora retorna o ID gerado
    final cartItemId = await CartRepository.add(
      userId: user,
      productId: productId,
      quantity: quantity,
    );

    return Response.json(
      body: {
        'result': {
          'id': cartItemId,
          'user': user,
          'productId': productId,
          'quantity': quantity,
          'message': 'Item processado com sucesso no carrinho.',
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro interno.',
        'error': e.toString(),
      },
    );
  }
}
