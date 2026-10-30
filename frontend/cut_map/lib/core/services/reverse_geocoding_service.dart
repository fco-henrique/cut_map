import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class AddressSuggestion {
  const AddressSuggestion({
    this.street,
    this.number,
    this.neighborhood,
    this.city,
    this.stateCode,
  });

  final String? street;
  final String? number;
  final String? neighborhood;
  final String? city;
  final String? stateCode;

  bool get isEmpty =>
      street == null && city == null && stateCode == null;
}

class ReverseGeocodingService {
  ReverseGeocodingService()
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://nominatim.openstreetmap.org',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {
            'User-Agent': 'CutMap/1.0 (com.example.cut_map)',
            'Accept-Language': 'pt-BR,pt;q=0.9',
          },
        ));

  final Dio _dio;
  final Map<String, AddressSuggestion?> _cache = {};
  DateTime? _lastRequest;

  static const _brazilianStates = <String, String>{
    'acre': 'AC', 'alagoas': 'AL', 'amapa': 'AP', 'amazonas': 'AM',
    'bahia': 'BA', 'ceara': 'CE', 'distrito federal': 'DF',
    'espirito santo': 'ES', 'goias': 'GO', 'maranhao': 'MA',
    'mato grosso': 'MT', 'mato grosso do sul': 'MS', 'minas gerais': 'MG',
    'para': 'PA', 'paraiba': 'PB', 'parana': 'PR', 'pernambuco': 'PE',
    'piaui': 'PI', 'rio de janeiro': 'RJ', 'rio grande do norte': 'RN',
    'rio grande do sul': 'RS', 'rondonia': 'RO', 'roraima': 'RR',
    'santa catarina': 'SC', 'sao paulo': 'SP', 'sergipe': 'SE',
    'tocantins': 'TO',
  };

  Future<AddressSuggestion?> lookup(LatLng point) async {
    final key = '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    if (_cache.containsKey(key)) return _cache[key];

    final previous = _lastRequest;
    if (previous != null) {
      final wait = const Duration(seconds: 1) - DateTime.now().difference(previous);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastRequest = DateTime.now();

    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: {
        'format': 'jsonv2',
        'addressdetails': 1,
        'layer': 'address',
        'lat': point.latitude,
        'lon': point.longitude,
      },
    );
    final raw = response.data?['address'];
    if (raw is! Map) return null;
    final address = Map<String, dynamic>.from(raw);
    String? first(List<String> keys) {
      for (final key in keys) {
        final value = address[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
      return null;
    }

    final iso = first(['ISO3166-2-lvl4', 'ISO3166-2-lvl6']);
    final state = first(['state']);
    final stateCode = iso != null && iso.startsWith('BR-')
        ? iso.substring(3).toUpperCase()
        : state == null ? null : _brazilianStates[_normalize(state)];
    final suggestion = AddressSuggestion(
      street: first(['road', 'pedestrian', 'residential', 'footway']),
      number: first(['house_number']),
      neighborhood: first([
        'suburb', 'neighbourhood', 'city_district', 'quarter', 'district',
      ]),
      city: first(['city', 'town', 'village', 'municipality', 'county']),
      stateCode: stateCode,
    );
    _cache[key] = suggestion.isEmpty ? null : suggestion;
    return _cache[key];
  }

  String _normalize(String value) {
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'é': 'e', 'ê': 'e',
      'í': 'i', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ç': 'c',
    };
    var result = value.toLowerCase();
    accents.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }
}
