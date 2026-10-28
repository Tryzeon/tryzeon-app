import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/common/product_color/data/product_color_table.dart';

extension ProductColorOrder<T> on PostgrestTransformBuilder<T> {
  /// PostgREST returns an embedded relation unordered unless asked; the cover
  /// is the first colour in this order, as in the shop RPCs.
  PostgrestTransformBuilder<T> orderProductColors() =>
      order(
            'position',
            ascending: true,
            referencedTable: ProductColorTable.name,
          )
          .order(
            'created_at',
            ascending: true,
            referencedTable: ProductColorTable.name,
          )
          .order(
            'id',
            ascending: true,
            referencedTable: ProductColorTable.name,
          );
}
