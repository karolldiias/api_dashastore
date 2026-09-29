import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/mocks/qrcode_mock.dart';
import 'package:api_dashastore_cupcake/repositories/cart_repository.dart';
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
    // 1. Pega o token do cabeçalho Authorization enviado pelo Front-end
    final headers = context.request.headers;
    final authorization =
        headers['Authorization'] ?? headers['authorization'] ?? '';

    if (authorization.isEmpty || !authorization.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {
          'success': false,
          'message': 'Token não fornecido no cabeçalho Authorization.',
        },
      );
    }

    final token = authorization.substring(7).trim();

    // 2. Extrai o userId (sub) direto do Token JWT sem fazer requisição ao Supabase Auth
    final userId = _extractUserIdFromJwt(token);

    // 3. Lê o corpo com o total enviado pelo Flutter
    final body = await context.request.json() as Map<String, dynamic>;
    final totalInformado = double.tryParse(body['total'].toString()) ?? 0.0;

    // 4. Busca o carrinho do usuário na nuvem usando o ID extraído
    final carrinho = await CartRepository.getAll(userId);

    if (carrinho.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'Carrinho vazio.',
          // ignore: inference_failure_on_collection_literal
          'result': {},
        },
      );
    }

    double totalCalculado = 0;

    // 5. Calcula o total com base nos preços dos produtos vinculados
    for (final item in carrinho) {
      final productMap = item['product'] as Map<String, dynamic>?;
      if (productMap == null) continue;

      final price = double.tryParse(productMap['price'].toString()) ?? 0.0;
      final quantity = int.tryParse(item['quantity'].toString()) ?? 0;

      totalCalculado += price * quantity;
    }

    // Validação de segurança do total
    if ((totalCalculado - totalInformado).abs() > 0.01) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'message': 'O total informado não corresponde ao total calculado.',
          'totalInformado': totalInformado,
          'totalCalculado': totalCalculado,
        },
      );
    }

    // 6. Monta a lista de itens estruturada para a resposta do front-end
    final orderItems = <Map<String, dynamic>>[];
    for (final item in carrinho) {
      final productMap = item['product'] as Map<String, dynamic>?;
      if (productMap != null) {
        orderItems.add({
          'id':
              item['id']?.toString() ??
              'cart_${DateTime.now().millisecondsSinceEpoch}',
          'quantity': item['quantity'],
          'product': productMap,
        });
      }
    }

    // 1. Captura o momento atual do servidor local (Horário do Brasil)
    final agoraLocal = DateTime.now();

    // 2. Adiciona 1 hora completa de validade para o PIX baseada no relógio do Brasil
    final vencimentoLocal = agoraLocal.add(const Duration(hours: 1));

    // 7. Estrutura o mapa do pedido
    final order = {
      'id': 'order_${agoraLocal.millisecondsSinceEpoch}',
      'user': userId,
      'total': totalCalculado,
      'items': orderItems,
      'qrCodeImage': mockQrCodeBase64,
      'copiaecola':
          '00020126580014BR.GOV.BCB.PIX0136MOCKPIX${agoraLocal.millisecondsSinceEpoch}',
      'due': vencimentoLocal.toUtc().toIso8601String(),
      'createdAt': agoraLocal.toUtc().toIso8601String(),
      'status': 'pending_payment',
    };

    // 8. Salva na nuvem (Supabase) e limpa o carrinho
    await OrderRepository.add(order);
    await CartRepository.clear(userId);

    return Response.json(
      body: {
        'result': order,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Erro ao finalizar pedido.',
        'error': e.toString(),
      },
    );
  }
}

/// Função auxiliar síncrona para decodificar a seção do meio (payload) de um JWT do Supabase e ler a chave 'sub' (ID do usuário)
String _extractUserIdFromJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Formato de token inválido.');
    }

    // Normaliza a string base64 adicionando os caracteres de padding '=' se necessário
    var output = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
      case 3:
        output += '=';
      default:
        throw Exception('String base64 corrompida.');
    }

    final payloadString = utf8.decode(base64Url.decode(output));
    final payloadJson = jsonDecode(payloadString) as Map<String, dynamic>;

    // No Supabase Auth, o ID do usuário (UUID) fica guardado na claim padrão 'sub'
    return payloadJson['sub']?.toString() ?? '';
  } catch (_) {
    throw Exception('Falha ao processar as credenciais contidas no Token.');
  }
}
