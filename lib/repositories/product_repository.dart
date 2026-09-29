import 'package:api_dashastore_cupcake/database/supabase_database.dart';

class ProductRepository {
  static Future<List<Map<String, dynamic>>> getAll() async {
    final result = await SupabaseDatabase.client.from('products').select('''
        id,
        title,
        description,
        price,
        unit,
        picture,
        categories!category_id (
          id,
          title
        )
      ''');

    return List<Map<String, dynamic>>.from(
      result.map((product) {
        final category = product['categories'] as Map<String, dynamic>?;

        return {
          'id': product['id'],
          'title': product['title'],
          'description': product['description'],
          'price': double.tryParse(product['price'].toString()) ?? 0.0,
          'unit': product['unit'],
          'picture': product['picture'],
          'category': {
            'id': category?['id'],
            'title': category?['title'],
          },
        };
      }),
    );
  }

  static Future<Map<String, dynamic>?> getById(
    String id,
  ) async {
    final result = await SupabaseDatabase.client
        .from('products')
        .select('''
          id,
          title,
          description,
          price,
          unit,
          picture,
          categories!category_id (
            id,
            title
          )
        ''')
        .eq('id', id)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    final category = result['categories'] as Map<String, dynamic>?;

    return {
      'id': result['id'],
      'title': result['title'],
      'description': result['description'],
      'price': double.parse(result['price'].toString()),
      'unit': result['unit'],
      'picture': result['picture'],
      'category': {
        'id': category?['id'],
        'title': category?['title'],
      },
    };
  }
}
