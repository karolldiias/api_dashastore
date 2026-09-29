import 'package:dart_frog/dart_frog.dart';
import 'package:api_dashastore_cupcake/repositories/user_repository.dart';

Future<Response> onRequest(
  RequestContext context,
) async {
  return Response.json(
    body: {
      'result': UserRepository.getAll(),
    },
  );
}
