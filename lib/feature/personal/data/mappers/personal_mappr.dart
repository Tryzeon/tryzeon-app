import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/core/utils/public_image_url.dart';
import 'package:tryzeon/feature/common/clothing_style/data/mappers/clothing_style_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/data/mappers/garment_type_cache_converters.dart';
import 'package:tryzeon/feature/common/garment_type/domain/entities/garment_type.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/profile_cache_converters.dart';

import '../../../../feature/common/body_measurements/data/mappers/body_measurements_mappr.dart';
import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_size/data/dtos/product_size_dto.dart';
import '../../../../feature/common/product_size/data/mappers/body_measurement_ranges_mappr.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../../../feature/common/product_size/domain/entities/product_size.dart';
import '../../../common/store/data/dtos/store_order_contact_dto.dart';
import '../../../common/store/domain/entities/store_channel.dart';
import '../../../common/store/domain/entities/store_order_contact.dart';
import '../../chat/data/dtos/chat_answer_block_dto.dart';
import '../../chat/data/dtos/chat_answer_dto.dart';
import '../../chat/data/dtos/chat_content_block_dto.dart';
import '../../chat/data/dtos/chat_message_dto.dart';
import '../../chat/data/dtos/chat_stream_event_dto.dart';
import '../../chat/domain/entities/chat_message.dart';
import '../../chat/domain/entities/content_block.dart';
import '../../profile/data/collections/user_profile_cache.dart';
import '../../profile/data/dtos/update_user_profile_request.dart';
import '../../profile/data/dtos/user_profile_dto.dart';
import '../../profile/domain/entities/age_range.dart';
import '../../profile/domain/entities/gender.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../profile/domain/entities/user_profile_update.dart';
import '../../shop/data/dtos/shop_product_dto.dart';
import '../../shop/data/dtos/shop_store_info_dto.dart';
import '../../shop/domain/entities/shop_product.dart';
import '../../shop/domain/entities/shop_store_info.dart';
import '../../shop/shop.dart' show decodeShopProductRow;
import '../../subscription/data/collections/subscription_tier_cache.dart';
import '../../subscription/data/dtos/subscription_tier_dto.dart';
import '../../subscription/domain/entities/subscription_capabilities.dart';
import '../../tryon/data/dtos/base64_image_dto.dart';
import '../../tryon/data/dtos/tryon_function_request.dart';
import '../../tryon/data/dtos/tryon_garment_dto.dart';
import '../../tryon/domain/entities/tryon_garment.dart';
import '../../tryon/domain/entities/tryon_request.dart';
import '../../wardrobe/data/collections/wardrobe_item_cache.dart';
import '../../wardrobe/data/dtos/create_wardrobe_item_request.dart';
import '../../wardrobe/data/dtos/label_result_dto.dart';
import '../../wardrobe/data/dtos/update_wardrobe_item_request.dart';
import '../../wardrobe/data/dtos/wardrobe_item_dto.dart';
import '../../wardrobe/domain/entities/label_result.dart';
import '../../wardrobe/domain/entities/new_wardrobe_item.dart';
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import '../../wardrobe/domain/entities/wardrobe_item_update.dart';
import '../../wardrobe/wardrobe.dart' show decodeWardrobeItemRow;
import 'personal_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<UserProfileDto, UserProfile>(),
    MapType<UserProfileUpdate, UpdateUserProfileRequest>(),
    MapType<UserProfile, UserProfileCache>(
      converters: [
        TypeConverter<Gender?, String?>(ProfileCacheConverters.genderToCache),
        TypeConverter<AgeRange?, String?>(
          ProfileCacheConverters.ageRangeToCache,
        ),
        TypeConverter<List<ClothingStyle>?, List<String>?>(
          ClothingStyleCacheConverters.listToCache,
        ),
      ],
    ),
    MapType<UserProfileCache, UserProfile>(
      converters: [
        TypeConverter<String?, Gender?>(ProfileCacheConverters.genderFromCache),
        TypeConverter<String?, AgeRange?>(
          ProfileCacheConverters.ageRangeFromCache,
        ),
        TypeConverter<List<String>?, List<ClothingStyle>?>(
          ClothingStyleCacheConverters.listFromCache,
        ),
      ],
    ),

    MapType<WardrobeItemDto, WardrobeItem>(),
    MapType<LabelResultDto, LabelResult>(),
    MapType<NewWardrobeItem, CreateWardrobeItemRequest>(),
    MapType<WardrobeItemUpdate, UpdateWardrobeItemRequest>(),
    MapType<WardrobeItem, WardrobeItemCache>(
      fields: [Field('itemId', from: 'id')],
      converters: [
        TypeConverter<GarmentType, String>(GarmentTypeCacheConverters.toCache),
      ],
    ),
    MapType<WardrobeItemCache, WardrobeItem>(
      fields: [Field('id', from: 'itemId')],
      converters: [
        TypeConverter<String, GarmentType>(
          GarmentTypeCacheConverters.fromCache,
        ),
      ],
    ),
    MapType<ShopProductDto, ShopProduct>(
      fields: [Field('imageUrls', custom: ShopMapprHelper.imageUrlsToEntity)],
    ),

    MapType<StoreOrderContactDto, StoreOrderContact>(),

    MapType<ShopStoreInfoDto, ShopStoreInfo>(
      fields: [
        Field('channels', custom: ShopMapprHelper.channelsToEntity),
        Field('logoUrl', custom: ShopMapprHelper.logoUrlToEntity),
      ],
    ),

    MapType<ProductSizeDto, ProductSize>(),

    MapType<SubscriptionTierDto, SubscriptionCapabilities>(
      fields: [
        Field('dailyTryonLimit', from: 'tryonLimit'),
        Field('dailyChatLimit', from: 'chatLimit'),
        Field('dailyVideoLimit', from: 'videoLimit'),
      ],
    ),
    MapType<SubscriptionCapabilities, SubscriptionTierCache>(),
    MapType<SubscriptionTierCache, SubscriptionCapabilities>(),

    MapType<ChatMessage, ChatMessageDto>(
      fields: [Field('content', custom: ChatMapprHelper.contentToDto)],
    ),
    MapType<ChatAnswerDto, ChatMessage>(
      fields: [Field('content', custom: ChatMapprHelper.answerContentToEntity)],
    ),
    MapType<ChatToolUseEventDto, ToolUseBlock>(),
    MapType<ChatToolResultEventDto, ToolResultBlock>(),

    MapType<TryonGenerateRequest, TryonFunctionRequest>(
      fields: [
        Field('generationId', from: 'requestId'),
        Field('garments', custom: TryonMapprHelper.garmentsToDto),
        Field('avatar', custom: TryonMapprHelper.avatarToDto),
      ],
    ),
    MapType<TryonAnimateRequest, TryonFunctionRequest>(
      fields: [
        Field('generationId', from: 'requestId'),
        Field('baseImage', custom: TryonMapprHelper.baseImageToDto),
      ],
    ),
  ],
  includes: [
    BodyMeasurementsMappr(), // UserProfile(Update).measurements
    GarmentMeasurementsMappr(), // ProductSize.measurements
    BodyMeasurementRangesMappr(), // ProductSize.bodyMeasurementRanges
  ],
)
class PersonalMappr extends $PersonalMappr {
  const PersonalMappr();
}

class ShopMapprHelper {
  static List<String> imageUrlsToEntity(final ShopProductDto source) =>
      source.imagePaths.map(PublicImageUrl.of).toList();

  static Set<StoreChannel> channelsToEntity(final ShopStoreInfoDto source) =>
      source.channels.toSet();

  static String? logoUrlToEntity(final ShopStoreInfoDto source) =>
      PublicImageUrl.ofOrNull(source.logoPath);
}

class ChatMapprHelper {
  static List<ChatContentBlockDto> contentToDto(final ChatMessage source) => [
    for (final block in source.content)
      switch (block) {
        TextBlock(:final text) => ChatContentBlockDto.text(text: text),
        ToolUseBlock(:final id, :final name, :final input) =>
          ChatContentBlockDto.toolUse(id: id, name: name, input: input),
        ToolResultBlock(:final toolUseId, :final content) =>
          ChatContentBlockDto.toolResult(
            toolUseId: toolUseId,
            content: content,
          ),
        ShopProductBlock(:final product) => ChatContentBlockDto.product(
          id: product.id,
        ),
        WardrobeProductBlock(:final item) => ChatContentBlockDto.wardrobe(
          id: item.id,
        ),
      },
  ];

  static List<ContentBlock> answerContentToEntity(final ChatAnswerDto source) =>
      [
        for (final block in source.content)
          ?switch (block) {
            ChatAnswerTextDto(:final text) => ContentBlock.text(text),
            ChatAnswerProductDto(:final item) => ContentBlock.shopProduct(
              decodeShopProductRow(item),
            ),
            ChatAnswerWardrobeDto(:final item) => ContentBlock.wardrobeProduct(
              decodeWardrobeItemRow(item),
            ),
            ChatAnswerUnknownDto() => null,
          },
      ];
}

class TryonMapprHelper {
  static List<TryonGarmentDto> garmentsToDto(
    final TryonGenerateRequest source,
  ) => [
    for (final garment in source.garments)
      switch (garment) {
        TryonGarmentProduct(:final productId, :final sizeId) =>
          TryonProductGarmentDto(productId: productId, sizeId: sizeId),
        TryonGarmentWardrobe(:final wardrobeItemId) => TryonWardrobeGarmentDto(
          wardrobeItemId: wardrobeItemId,
        ),
        TryonGarmentImages(:final base64Images) => TryonImagesGarmentDto(
          images: base64Images.map(Base64ImageDto.new).toList(),
        ),
      },
  ];

  static Base64ImageDto? avatarToDto(final TryonGenerateRequest source) =>
      switch (source.avatarBase64) {
        final avatar? => Base64ImageDto(avatar),
        null => null,
      };

  static Base64ImageDto baseImageToDto(final TryonAnimateRequest source) =>
      Base64ImageDto(source.baseImageBase64);
}
