import 'package:cut_map/models/address_model.dart';
import 'package:cut_map/models/barbershop_model.dart';
import 'package:cut_map/models/opening_hours_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final shop = BarbershopModel(
    id: '1',
    name: 'Barbearia Central',
    address: AddressModel(latitude: -23.55, longitude: -46.63),
    openingHours: const [
      OpeningHoursModel(
        dayOfWeek: DateTime.monday,
        opensAt: '09:00',
        closesAt: '18:00',
        breakStartsAt: '12:00',
        breakEndsAt: '13:00',
      ),
    ],
  );

  test('considera expediente e pausa ao indicar aberto ou fechado', () {
    expect(shop.isOpenAt(DateTime(2026, 10, 26, 10)), isTrue);
    expect(shop.isOpenAt(DateTime(2026, 10, 26, 12, 30)), isFalse);
    expect(shop.isOpenAt(DateTime(2026, 10, 26, 13)), isTrue);
    expect(shop.isOpenAt(DateTime(2026, 10, 26, 18)), isFalse);
    expect(shop.isOpenAt(DateTime(2026, 10, 27, 10)), isFalse);
  });

  test('não informa estado sem horários cadastrados', () {
    final withoutHours = BarbershopModel(
      id: '2',
      name: 'Sem horários',
      address: AddressModel(),
    );

    expect(withoutHours.isOpenAt(DateTime(2026, 10, 26, 10)), isNull);
  });

  test('calcula distância apenas com origem e destino disponíveis', () {
    expect(shop.distanceFrom(const LatLng(-23.55, -46.63)), closeTo(0, 0.001));
    expect(shop.distanceFrom(null), isNull);
  });
}
