import 'package:api_dashastore_cupcake/database/supabase_database.dart';
import 'package:dart_frog/dart_frog.dart';

bool _initialized = false;

Handler middleware(Handler handler) {
  return (context) async {
    if (!_initialized) {
      SupabaseDatabase.initialize();

      _initialized = true;
    }

    if (context.request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        },
      );
    }

    final response = await handler(context);

    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization, X-Requested-With',
      },
    );
  };
}
