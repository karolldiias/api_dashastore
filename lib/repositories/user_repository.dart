import 'dart:io';
import 'package:api_dashastore_cupcake/database/supabase_database.dart';
import 'package:supabase/supabase.dart';

class UserRepository {
  // Retorna todos os perfis cadastrados na tabela pública
  static Future<List<Map<String, dynamic>>> getAll() async {
    final result = await SupabaseDatabase.client.from('users').select();
    return List<Map<String, dynamic>>.from(result);
  }

  // Cadastra a credencial no módulo Auth e vincula os dados extras na tabela pública
  static Future<Map<String, dynamic>> signUp({
    required String fullname,
    required String email,
    required String phone,
    required String cpf,
    required String password,
  }) async {
    // 1. Cria o usuário no gerenciador de autenticação segura do Supabase
    final response = await SupabaseDatabase.client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Erro ao registrar usuário no sistema de autenticação.');
    }

    final dadosUsuario = {
      'id': user.id, // ID gerado pelo Supabase Auth (UUID)
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'cpf': cpf,
    };

    // 2. Insere os dados adicionais na tabela pública de usuários
    await SupabaseDatabase.client.from('users').insert(dadosUsuario);

    // 3. LOGAR AUTOMATICAMENTE para obter um token real (Garante estabilidade no fluxo Implicit)
    final loginResponse = await SupabaseDatabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Adiciona o token da sessão no mapa para manter compatibilidade com seu front-end
    dadosUsuario['token'] = loginResponse.session?.accessToken ?? '';
    dadosUsuario['password'] = password;

    return dadosUsuario;
  }

  // Busca o usuário pelo E-mail na tabela pública
  static Future<Map<String, dynamic>?> getByEmail(String email) async {
    final result = await SupabaseDatabase.client
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();
    return result;
  }

  // Busca o usuário pelo ID único (UUID)
  static Future<Map<String, dynamic>?> getById(String id) async {
    final result = await SupabaseDatabase.client
        .from('users')
        .select()
        .eq('id', id)
        .maybeSingle();
    return result;
  }

  /// Valida as credenciais atuais e altera para a nova senha diretamente no Supabase Auth
  static Future<void> updatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    // 1. Cria uma instância temporária dedicada utilizando a classe de constantes corrigida

    final url = Platform.environment['SUPABASE_URL'] ?? 'https://supabase.co';
    final anonKey =
        Platform.environment['SUPABASE_ANON_KEY'] ?? 'SUA_CHAVE_ANON_LOCAL';

    final clientTemporario = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    // 2. Faz o login usando a senha antiga nessa instância dedicada.
    final authResponse = await clientTemporario.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    if (authResponse.user == null || authResponse.session == null) {
      throw Exception('Senha atual inválida.');
    }

    // 3. Com a sessão autenticada ativa no cliente temporário, atualiza para a nova senha.
    await clientTemporario.auth.updateUser(
      UserAttributes(password: newPassword),
    );

    // 4. Faz o log out para limpar a sessão ativa no servidor
    await clientTemporario.auth.signOut();
  }

  /// Autentica o usuário no Supabase Auth e junta os dados extras da tabela pública
  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    // 1. Faz o login no gerenciador do Supabase (Verifica se a senha e e-mail batem)
    final response = await SupabaseDatabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user == null || session == null) {
      throw Exception('E-mail ou senha inválidos.');
    }

    // 2. Busca os dados adicionais (como fullname, phone, cpf) na tabela pública
    final profile = await SupabaseDatabase.client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Perfil do usuário não encontrado na base pública.');
    }

    // 3. Monta o mapa de retorno unificando o Token com os dados do perfil
    return {
      'id': profile['id'],
      'fullname': profile['fullname'],
      'email': profile['email'],
      'phone': profile['phone'],
      'cpf': profile['cpf'],
      'password':
          password, // Mantém a senha no retorno para compatibilidade com o seu código original
      'token': session.accessToken, // Token JWT real do Supabase
    };
  }

  /// Envia um e-mail de redefinição de senha seguro para o usuário
  static Future<void> sendPasswordResetEmail(String email) async {
    await SupabaseDatabase.client.auth.resetPasswordForEmail(
      email,
    );
  }

  /// Valida um token JWT do Supabase Auth e retorna os dados do perfil público
  static Future<Map<String, dynamic>?> validateSessionToken(
    String token,
  ) async {
    try {
      // 1. Envia o token para o Supabase descriptografar e validar
      final response = await SupabaseDatabase.client.auth.getUser(token);
      final user = response.user;

      if (user == null) {
        return null;
      }

      // 2. Se o token for válido, busca os dados públicos associados ao ID dele
      final profile = await SupabaseDatabase.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        return null;
      }

      // 3. Monta o mapa de retorno unificando os informações
      return {
        'id': profile['id'],
        'fullname': profile['fullname'],
        'email': profile['email'],
        'phone': profile['phone'],
        'cpf': profile['cpf'],
        'token': token, // Devolve o mesmo token recebido para o front-end
      };
    } catch (_) {
      return null;
    }
  }
}
