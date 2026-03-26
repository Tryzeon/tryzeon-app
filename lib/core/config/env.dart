import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL', defaultValue: 'https://placeholder.supabase.co')
  static final String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', defaultValue: 'placeholder-key')
  static final String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'REVENUE_CAT_API_KEY', defaultValue: 'placeholder-key')
  static final String revenueCatApiKey = _Env.revenueCatApiKey;
}
