import 'package:supabase_flutter/supabase_flutter.dart';

/// Answers every `invoke` with [data], or throws [error].
class FakeFunctionsClient implements FunctionsClient {
  FakeFunctionsClient({this.data, this.error});

  final Object? data;
  final Object? error;
  String? invokedFunction;
  Map<String, dynamic>? sentBody;

  @override
  dynamic noSuchMethod(final Invocation invocation) {
    invokedFunction = invocation.positionalArguments.first as String;
    sentBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
    if (error case final error?) return Future<FunctionResponse>.error(error);
    return Future.value(FunctionResponse(data: data, status: 200));
  }
}

class FakeSupabaseClient implements SupabaseClient {
  FakeSupabaseClient(this.functions);

  @override
  final FunctionsClient functions;

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
