import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/cart_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  // Permite OPTIONS
  if (context.request.method == HttpMethod.options) {
    return Response(statusCode: 204);
  }

  // Aceita apenas POST
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: 405,
      body: 'Apenas método POST é permitido.',
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;

    final cartItemId = body['cartItemId']?.toString().trim();
    final quantity = int.tryParse(body['quantity']?.toString() ?? '');

    // Validação do ID do item do carrinho (deve ser o ID/UUID gerado na tabela 'cart')
    if (cartItemId == null || cartItemId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'cartItemId é obrigatório.',
        },
      );
    }

    // Validação da quantidade
    if (quantity == null || quantity < 0) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Quantidade inválida.',
        },
      );
    }

    // 1. Busca de forma assíncrona se o item realmente existe na tabela 'cart' do Supabase
    final itemEncontrado = await CartRepository.getById(cartItemId);

    if (itemEncontrado == null) {
      return Response.json(
        statusCode: 404,
        body: {
          'success': false,
          'message': 'Item não encontrado no carrinho.',
        },
      );
    }

    // 2. Regra de Negócio: Se a quantidade for igual a 0, remove o registro do banco
    if (quantity == 0) {
      await CartRepository.removeById(cartItemId);

      return Response.json(
        body: {
          'success': true,
          'message': 'Item removido do carrinho.',
          'result': {
            'id': itemEncontrado['id'],
            'quantity': itemEncontrado['quantity'],
          },
        },
      );
    }

    // Atualiza a quantidade na nuvem e captura o mapa populado do banco
    final itemAtualizado = await CartRepository.updateQuantity(
      cartItemId,
      quantity,
    );

    // Retorne o objeto atualizado dentro da chave 'result' para o front-end mapear sem nulos!
    return Response.json(
      body: {
        'success': true,
        'result': {
          'id': itemAtualizado['id'],
          'quantity': itemAtualizado['quantity'],
          'product':
              itemAtualizado['product'], // Dados populados que o front precisa!
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
