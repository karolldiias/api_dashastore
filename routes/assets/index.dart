import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  final fileName = context.request.uri.queryParameters['file'];

  if (fileName == null || fileName.isEmpty) {
    return Response(
      statusCode: 400,
      body: 'Arquivo não informado.',
    );
  }

  final file = File(
    'assets/images/$fileName',
  );

  if (!await file.exists()) {
    return Response(
      statusCode: 404,
      body: 'Imagem não encontrada.',
    );
  }

  final bytes = await file.readAsBytes();

  return Response.bytes(
    body: bytes,
    headers: {
      'Content-Type': 'image/png',
    },
  );
}
