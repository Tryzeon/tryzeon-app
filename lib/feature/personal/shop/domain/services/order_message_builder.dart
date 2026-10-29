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
      '尺寸：${fitResult.sizeToOrder ?? '（未提供）'}',
      '數量：1',
      product.webUrl(color: color),
    ];
    return lines.join('\n');
  }
}
