enum PricingType { perThaal, perSize, perTray, perPerson }
enum PricingMode { manual, fromMenuItems }

extension PricingTypeX on PricingType {
  String get code => switch (this) {
    PricingType.perThaal => 'per_thaal',
    PricingType.perSize => 'per_size',
    PricingType.perTray => 'per_tray',
    PricingType.perPerson => 'per_person',
  };
}

extension PricingModeX on PricingMode {
  String get code => switch (this) {
    PricingMode.manual => 'manual',
    PricingMode.fromMenuItems => 'from_menu_items',
  };
}

enum Category { thaal, thaali, partyTray, liveBbq, buffet }

extension CategoryX on Category {
  String get label => switch (this) {
    Category.thaal => 'Thaal',
    Category.thaali => 'Thaali',
    Category.partyTray => 'Party Tray',
    Category.liveBbq => 'Live BBQ',
    Category.buffet => 'Buffet',
  };
}