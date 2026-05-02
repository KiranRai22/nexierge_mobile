// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'universal_request_order_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) => OrderItemDto(
  activeUniversalRequestId: json['active_universal_request_id'] as String,
  guestNotes: json['guest_notes'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  itemName: json['item_name'] as String,
);

Map<String, dynamic> _$OrderItemDtoToJson(OrderItemDto instance) =>
    <String, dynamic>{
      'active_universal_request_id': instance.activeUniversalRequestId,
      'guest_notes': instance.guestNotes,
      'price': instance.price,
      'quantity': instance.quantity,
      'item_name': instance.itemName,
    };

UniversalRequestOrderDto _$UniversalRequestOrderDtoFromJson(
  Map<String, dynamic> json,
) => UniversalRequestOrderDto(
  guestStayId: json['guest_stay_id'] as String,
  contactId: json['contact_id'] as String,
  hotelId: json['hotel_id'] as String,
  orderItems: (json['order_items'] as List<dynamic>)
      .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UniversalRequestOrderDtoToJson(
  UniversalRequestOrderDto instance,
) => <String, dynamic>{
  'guest_stay_id': instance.guestStayId,
  'contact_id': instance.contactId,
  'hotel_id': instance.hotelId,
  'order_items': instance.orderItems,
};

UniversalRequestOrderResponseDto _$UniversalRequestOrderResponseDtoFromJson(
  Map<String, dynamic> json,
) => UniversalRequestOrderResponseDto(
  id: json['id'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UniversalRequestOrderResponseDtoToJson(
  UniversalRequestOrderResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
};
