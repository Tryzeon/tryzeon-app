import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/product_color/domain/entities/product_color.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

class OrderMessageBuilder {
  const OrderMessageBuilder._();

  static String build({
    required final ShopProduct product,
    required final ProductColor? color,
    required final FitResult fitResult,
  }) {
    final named = product.colors.distinguishing(color);
    final lines = <String>[
      '【Tryzeon 試穿下單】',
      '商品：${product.name}',
      if (named?.name != null) '顏色：${named!.name}',
      '尺寸：${_sizeLine(fitResult)}',
      '數量：1',
      AppConstants.productWebUrl(product.id, colorId: named?.id),
    ];
    return lines.join('\n');
  }

  static String _sizeLine(final FitResult fitResult) {
    final size = fitResult.recommendedSize;
    if (fitResult.noUserData || size == null) return '（未提供）';
    return size;
  }
}
