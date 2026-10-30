import 'package:cut_map/common/utils/json_parsers.dart';

class AddressModel {
  final String? cep;
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? pais;
  final double? latitude;
  final double? longitude;

  AddressModel({
    this.cep,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.pais,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      cep: json['cep'],
      rua: json['rua'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      pais: json['pais'],
      latitude: JsonParsers.toDoubleOrNull(json['latitude']),
      longitude: JsonParsers.toDoubleOrNull(json['longitude']),
    );
  }

  String get formatted =>
      [rua, numero, bairro, cidade].where((e) => e != null && e.isNotEmpty).join(', ');
}