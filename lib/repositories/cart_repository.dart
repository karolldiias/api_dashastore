import 'package:api_dashastore_cupcake/database/supabase_database.dart';

class CartRepository {
  // Busca todos os itens do carrinho tratando possíveis valores nulos do banco
  static Future<List<Map<String, dynamic>>> getAll(String userId) async {
    final result = await SupabaseDatabase.client
        .from('cart')
        .select('''
          id,
          quantity,
          product:products (
            id,
            title,
            price,
            picture,
            unit,
            description,
            category:categories!fk_products_categories (
              id,
              title
            )
          )
        ''')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(
      result.map((item) {
        final productMap = item['product'] as Map<String, dynamic>?;
        final categoryMap = productMap?['category'] as Map<String, dynamic>?;

        return {
          'id': item['id']?.toString() ?? '',
          'quantity': int.tryParse(item['quantity'].toString()) ?? 1,
          'product': {
            'id': productMap?['id']?.toString() ?? 'unknown',
            'title': productMap?['title']?.toString() ?? 'Produto sem título',
            'price':
                double.tryParse(productMap?['price']?.toString() ?? '0.0') ??
                0.0,
            'picture': productMap?['picture']?.toString() ?? '',
            'unit': productMap?['unit']?.toString() ?? 'un',
            'description': productMap?['description']?.toString() ?? '',
            'category': {
              'id': categoryMap?['id']?.toString() ?? 'unknown',
              'title': categoryMap?['title']?.toString() ?? 'Sem categoria',
            },
          },
        };
      }),
    );
  }

  // Adiciona um item ao carrinho ou soma a quantidade se o produto já existir
  static Future<String> add({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    // 1. Verifica se o produto já está no carrinho desse usuário
    final itemExistente = await SupabaseDatabase.client
        .from('cart')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    if (itemExistente != null) {
      final novaQuantidade = (itemExistente['quantity'] as int) + quantity;
      await updateQuantity(itemExistente['id'].toString(), novaQuantidade);
      return itemExistente['id'].toString();
    } else {
      // 2. Insere o item novo e captura o ID gerado na tabela 'cart'
      final novoItem = await SupabaseDatabase.client
          .from('cart')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'quantity': quantity,
          })
          .select('id')
          .single();

      return novoItem['id'].toString();
    }
  }

  // Limpa todo o carrinho do usuário
  static Future<void> clear(String userId) async {
    await SupabaseDatabase.client.from('cart').delete().eq('user_id', userId);
  }

  // Remove um item específico pelo ID único do carrinho (Chave Primária da tabela cart)
  static Future<void> removeById(String cartItemId) async {
    await SupabaseDatabase.client.from('cart').delete().eq('id', cartItemId);
  }

  // Atualiza a quantidade de um item e já retorna o item atualizado com Produto e Categoria
  static Future<Map<String, dynamic>> updateQuantity(
    String cartItemId,
    int quantity,
  ) async {
    final result = await SupabaseDatabase.client
        .from('cart')
        .update({'quantity': quantity})
        .eq(
          'id',
          cartItemId,
        )
        .select('''
          id,
          quantity,
          product:products (
            id,
            title,
            price,
            picture,
            unit,
            description,
            category:categories!fk_products_categories (
              id,
              title
            )
          )
        ''')
        .single();

    return result;
  }

  // Busca um item específico do carrinho pelo ID
  static Future<Map<String, dynamic>?> getById(String cartItemId) async {
    final result = await SupabaseDatabase.client
        .from('cart')
        .select('''
          id,
          quantity,
          product:products (
            id,
            title,
            price,
            picture,
            unit
          )
        ''')
        .eq('id', cartItemId)
        .maybeSingle();

    return result;
  }
}
