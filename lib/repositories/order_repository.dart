import 'package:api_dashastore_cupcake/database/supabase_database.dart';

class OrderRepository {
  /// Salva o pedido completo separando os dados em orders e order_items
  static Future<void> add(Map<String, dynamic> order) async {
    // 1. Salva o cabeçalho do pedido (tabela orders)
    await SupabaseDatabase.client.from('orders').insert({
      'id': order['id'],
      'user_id': order['user'],
      'total': order['total'],
      'status': order['status'],
      'qr_code_image': order['qrCodeImage'],
      'copiaecola': order['copiaecola'],
      'due': order['due'],
      'created_at': order['createdAt'],
    });

    // 2. Extrai e prepara a lista de itens
    final items = order['items'] as List;
    final itemsParaInserir = <Map<String, dynamic>>[];

    for (final item in items) {
      final mapaItem = item as Map<String, dynamic>;
      final produto = mapaItem['product'] as Map<String, dynamic>;

      itemsParaInserir.add({
        'id': 'item_${DateTime.now().millisecondsSinceEpoch}_${produto['id']}',
        'order_id': order['id'],
        'product_id': produto['id'].toString(),
        'quantity': mapaItem['quantity'],
      });
    }

    // 3. Salva todos os itens do pedido em lote (Bulk insert)
    if (itemsParaInserir.isNotEmpty) {
      await SupabaseDatabase.client
          .from('order_items')
          .insert(itemsParaInserir);
    }
  }

  /// Retorna o histórico de pedidos de forma assíncrona
  static Future<List<Map<String, dynamic>>> getAll() async {
    final result = await SupabaseDatabase.client.from('orders').select();
    return List<Map<String, dynamic>>.from(result);
  }

  /// Busca um pedido específico e resolve todo o relacionamento de seus itens e produtos
  static Future<Map<String, dynamic>?> getById(String orderId) async {
    final result = await SupabaseDatabase.client
        .from('orders')
        .select('''
          id,
          user_id,
          total,
          status,
          qr_code_image,
          copiaecola,
          due,
          created_at,
          order_items (
            id,
            quantity,
            products (
              id,
              title,
              description,
              price,
              unit,
              picture,
              category:categories!category_id (
                id,
                title
              )
            )
          )
        ''')
        .eq('id', orderId)
        .maybeSingle();

    return result;
  }

  /// Busca todo o histórico de pedidos de um usuário específico, trazendo seus itens e produtos estruturados
  static Future<List<Map<String, dynamic>>> getByUserId(String userId) async {
    final result = await SupabaseDatabase.client
        .from('orders')
        .select('''
          id,
          user_id,
          total,
          status,
          qr_code_image,
          copiaecola,
          due,
          created_at,
          order_items (
            id,
            quantity,
            products (
              id,
              title,
              description,
              price,
              unit,
              picture,
              category:categories!category_id (
                id,
                title
              )
            )
          )
        ''')
        .eq('user_id', userId)
        .order(
          'created_at',
        ); // Traz os pedidos mais recentes primeiro

    return List<Map<String, dynamic>>.from(result);
  }
}
