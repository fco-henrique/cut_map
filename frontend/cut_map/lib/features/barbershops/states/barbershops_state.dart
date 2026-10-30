import 'package:cut_map/models/barbershop_model.dart';

sealed class BarbershopsState {
  const BarbershopsState();
}

class BarbershopsInitial extends BarbershopsState {
  const BarbershopsInitial();
}

class BarbershopsLoading extends BarbershopsState {
  const BarbershopsLoading();
}

class BarbershopsLoaded extends BarbershopsState {
  const BarbershopsLoaded(this.items);
  final List<BarbershopModel> items;
}

class BarbershopsFailure extends BarbershopsState {
  const BarbershopsFailure(this.message);
  final String message;
}
