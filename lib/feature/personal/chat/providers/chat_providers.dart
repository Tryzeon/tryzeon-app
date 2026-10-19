import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/chat/domain/usecases/send_chat_message.dart';

part 'chat_providers.g.dart';

@riverpod
ChatRemoteDataSource chatRemoteDataSource(final Ref ref) {
  return ChatRemoteDataSource(
    ref.watch(supabaseClientProvider),
    ref.watch(dioProvider),
  );
}

@riverpod
ChatRepository chatRepository(final Ref ref) {
  final remoteDataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
SendChatMessage sendChatMessageUseCase(final Ref ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendChatMessage(repository);
}
