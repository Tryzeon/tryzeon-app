import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_block.freezed.dart';

/// One content block of a chat message — the standard chat-API shape (Anthropic
/// content blocks / OpenAI). A tool round spans messages: a [ToolUseBlock] in an
/// assistant message is paired (by [ToolUseBlock.id] ↔ [ToolResultBlock.toolUseId])
/// with a [ToolResultBlock] in the following user message. The calls of one
/// agent step share a message. Recommended items are referenced by id; what
/// they render as lives in `ChatItems`.
@freezed
sealed class ContentBlock with _$ContentBlock {
  const factory ContentBlock.text(final String text) = TextBlock;

  const factory ContentBlock.toolUse({
    required final String id,
    required final String name,
    @Default(<String, dynamic>{}) final Map<String, dynamic> input,
  }) = ToolUseBlock;

  /// The UI shows only the count of its `items`; the full content is replayed
  /// as a function response so the model sees exactly what each search returned.
  const factory ContentBlock.toolResult({
    required final String toolUseId,
    @Default(<String, dynamic>{}) final Map<String, dynamic> content,
  }) = ToolResultBlock;

  const factory ContentBlock.shopProduct(final String id) = ShopProductBlock;

  const factory ContentBlock.wardrobeProduct(final String id) =
      WardrobeProductBlock;
}
