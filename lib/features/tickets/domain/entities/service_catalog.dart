import '../../data/datasources/ticket_remote_data_source.dart';

/// Domain entity for Service Catalog
class ServiceCatalog {
  final String id;
  final String name;
  final String? description;
  final bool isEnabled;
  final String? brandColor;
  final String? logoUrl;
  final String? logoName;
  final int categories;
  final int items;
  final int sections;

  ServiceCatalog({
    required this.id,
    required this.name,
    this.description,
    this.isEnabled = true,
    this.brandColor,
    this.logoUrl,
    this.logoName,
    this.categories = 0,
    this.items = 0,
    this.sections = 0,
  });

  factory ServiceCatalog.fromDto(ServiceCatalogDto dto) {
    return ServiceCatalog(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      isEnabled: dto.isEnabled,
      brandColor: dto.brandColor,
      logoUrl: dto.logo?.url,
      logoName: dto.logo?.name,
      categories: dto.categories,
      items: dto.items,
      sections: dto.sections,
    );
  }
}
