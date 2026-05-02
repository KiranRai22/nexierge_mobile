import 'package:json_annotation/json_annotation.dart';

part 'universal_request_order_dto.g.dart';

/// Order item for universal request
@JsonSerializable()
class OrderItemDto {
  @JsonKey(name: 'active_universal_request_id')
  final String activeUniversalRequestId;
  
  @JsonKey(name: 'guest_notes')
  final String guestNotes;
  
  final double price;
  final int quantity;
  
  @JsonKey(name: 'item_name')
  final String itemName;

  const OrderItemDto({
    required this.activeUniversalRequestId,
    required this.guestNotes,
    required this.price,
    required this.quantity,
    required this.itemName,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}

/// Universal request order creation request
@JsonSerializable()
class UniversalRequestOrderDto {
  @JsonKey(name: 'guest_stay_id')
  final String guestStayId;
  
  @JsonKey(name: 'contact_id')
  final String contactId;
  
  @JsonKey(name: 'hotel_id')
  final String hotelId;
  
  @JsonKey(name: 'order_items')
  final List<OrderItemDto> orderItems;

  const UniversalRequestOrderDto({
    required this.guestStayId,
    required this.contactId,
    required this.hotelId,
    required this.orderItems,
  });

  factory UniversalRequestOrderDto.fromJson(Map<String, dynamic> json) =>
      _$UniversalRequestOrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UniversalRequestOrderDtoToJson(this);
}

/// Response from universal request order creation
@JsonSerializable()
class UniversalRequestOrderResponseDto {
  final String id;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const UniversalRequestOrderResponseDto({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory UniversalRequestOrderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UniversalRequestOrderResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UniversalRequestOrderResponseDtoToJson(this);
}
