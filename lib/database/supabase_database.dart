import 'dart:io';
import 'package:supabase/supabase.dart';

class SupabaseDatabase {
  static late final SupabaseClient client;

  static void initialize() {
    // 🌟 LÊ DA MEMÓRIA DO RENDER EM PRODUÇÃO.
    // Se estiver rodando local na sua máquina, ele usa o fallback (as strings de teste).
    final String url =
        Platform.environment['SUPABASE_URL'] ?? 'https://supabase.co';

    final String anonKey =
        Platform.environment['SUPABASE_ANON_KEY'] ??
        'SUA_CHAVE_ANON_DE_TESTES_LOCAL';

    client = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  }
}
