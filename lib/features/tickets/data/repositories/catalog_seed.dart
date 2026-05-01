import '../../domain/models/catalog.dart';
import '../../domain/models/department.dart';

/// Static catalog data. Swap with API later.
abstract class CatalogSeed {
  static List<Catalog> all() => [hotelRestaurant, roomService];

  static Catalog byId(String id) =>
      all().firstWhere((c) => c.id == id, orElse: () => hotelRestaurant);

  // ── Hotel Restaurant ──────────────────────────────────────────────────────
  static const Catalog hotelRestaurant = Catalog(
    id: 'cat_restaurant',
    name: 'Hotel Restaurant',
    description: 'Full-service hotel kitchen — breakfast, mains, drinks',
    emoji: '🍽️',
    department: Department.fnb,
    items: [
      CatalogItem(
        id: 'r_akara',
        name: 'Akara',
        description: 'African beans cake, served with bread',
        emoji: '🍲',
        basePrice: 5.00,
        optionGroups: [
          OptionGroup(
            id: 'onions',
            name: 'With Onions',
            type: OptionGroupType.singleSelect,
            required: true,
            options: [
              Option(id: 'yes', name: 'Yes'),
              Option(id: 'no', name: 'No'),
            ],
          ),
          OptionGroup(
            id: 'sides',
            name: 'Sides',
            type: OptionGroupType.multiAddOn,
            required: false,
            options: [
              Option(id: 'agege', name: 'Agege Bread', priceDelta: 9.50),
              Option(id: 'ogi', name: 'Bowl of Ogi (Pap)', priceDelta: 4.99),
            ],
          ),
        ],
      ),
      CatalogItem(
        id: 'r_small_chops',
        name: 'Small Chops',
        description: 'Family-size mixed Nigerian small chops platter',
        emoji: '🥡',
        basePrice: 25.00,
      ),
      CatalogItem(
        id: 'r_tea',
        name: 'Tea',
        description: 'Hot tea, served any time',
        emoji: '🍵',
        basePrice: 5.00,
      ),
      CatalogItem(
        id: 'r_coffee',
        name: 'Coffee',
        description: 'Freshly brewed coffee',
        emoji: '☕',
        basePrice: 6.50,
      ),
      CatalogItem(
        id: 'r_jollof',
        name: 'Jollof Rice',
        description: 'Classic Nigerian jollof, served with chicken',
        emoji: '🍛',
        basePrice: 18.00,
      ),
      CatalogItem(
        id: 'r_fruit_juice',
        name: 'Fresh fruit juice',
        description: 'Hand-pressed daily, ask staff for the fruit of the day',
        emoji: '🥤',
        basePrice: 7.50,
      ),
      CatalogItem(
        id: 'r_grilled_fish',
        name: 'Grilled fish',
        description: 'Catch of the day with seasonal vegetables',
        emoji: '🐟',
        basePrice: 22.00,
      ),
    ],
  );

  // ── Room Service ──────────────────────────────────────────────────────────
  static const Catalog roomService = Catalog(
    id: 'cat_room_service',
    name: 'Room Service',
    description: 'In-room amenities, late-night essentials',
    emoji: '🛎️',
    department: Department.fnb,
    items: [
      CatalogItem(
        id: 'rs_club_sandwich',
        name: 'Club sandwich',
        description: 'Triple-decker with chicken, bacon, and side fries',
        emoji: '🥪',
        basePrice: 14.00,
      ),
      CatalogItem(
        id: 'rs_burger_basket',
        name: 'Burger basket',
        description: 'Beef burger with house seasoning',
        emoji: '🍔',
        basePrice: 17.50,
      ),
      CatalogItem(
        id: 'rs_ice_cream',
        name: 'Ice cream',
        description: 'Two scoops, your choice of flavour',
        emoji: '🍨',
        basePrice: 6.00,
      ),
      CatalogItem(
        id: 'rs_tea_kettle',
        name: 'Tea kettle set',
        description: 'Kettle, sugar, milk and 4 tea bags',
        emoji: '🫖',
        basePrice: 0,
      ),
      CatalogItem(
        id: 'rs_red_wine',
        name: 'Red wine',
        description: 'House red, by the glass',
        emoji: '🍷',
        basePrice: 12.00,
      ),
      CatalogItem(
        id: 'rs_snack_pack',
        name: 'Snack pack',
        description: 'Mini bar essentials — chips, nuts, chocolate',
        emoji: '🥨',
        basePrice: 9.50,
      ),
      CatalogItem(
        id: 'rs_late_night_combo',
        name: 'Late night combo',
        description: 'Burger + fries + drink — available 11pm-5am only',
        emoji: '🌙',
        basePrice: 22.00,
        optionGroups: [
          OptionGroup(
            id: 'drink',
            name: 'Drink',
            type: OptionGroupType.singleSelect,
            required: true,
            options: [
              Option(id: 'soda', name: 'Soda'),
              Option(id: 'water', name: 'Water'),
              Option(id: 'juice', name: 'Juice'),
            ],
          ),
        ],
      ),
    ],
  );
}
