import 'package:envied/envied.dart';
import 'package:tryzeon/core/config/app_environment.dart';

part 'env.g.dart';

@Envied(path: '.env', name: 'ProductionEnv', obfuscate: true)
@Envied(path: '.env.local', name: 'LocalEnv', obfuscate: true)
final class Env {
  factory Env() => _instance;

  static final Env _instance = switch (AppEnvironment.current) {
    AppEnvironment.production => _ProductionEnv(),
    AppEnvironment.local => _LocalEnv(),
  };

  @EnviedField(varName: 'SUPABASE_URL')
  final String supabaseUrl = _instance.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  final String supabaseAnonKey = _instance.supabaseAnonKey;

  @EnviedField(varName: 'REVENUE_CAT_API_KEY')
  final String revenueCatApiKey = _instance.revenueCatApiKey;

  @EnviedField(varName: 'R2_PUBLIC_IMAGES_BASE_URL')
  final String r2PublicImagesBaseUrl = _instance.r2PublicImagesBaseUrl;
}
