import 'package:api_dashastore_cupcake/database/supabase_database.dart';

class CategoryRepository {
  // Busca todas as categorias do banco
  static Future<List<Map<String, dynamic>>> getAll() async {
    final result = await SupabaseDatabase.client.from('categories').select();

    return List<Map<String, dynamic>>.from(result);
  }

  // Adiciona uma nova categoria no banco
  static Future<void> add(
    Map<String, dynamic> category,
  ) async {
    await SupabaseDatabase.client.from('categories').insert(category);
  }

  // Busca uma categoria específica pelo ID
  static Future<Map<String, dynamic>?> getById(
    String categoryId,
  ) async {
    final result = await SupabaseDatabase.client
        .from('categories')
        .select()
        .eq('id', categoryId)
        .maybeSingle();

    return result;
  }
}
