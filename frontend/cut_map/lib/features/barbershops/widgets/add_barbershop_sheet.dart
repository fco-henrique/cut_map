import 'dart:math' as math;

import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/core/services/location_service.dart';
import 'package:cut_map/features/barbershops/controllers/add_barbershop_controller.dart';
import 'package:cut_map/features/barbershops/widgets/barbershop_location_picker.dart';
import 'package:cut_map/features/barbershops/widgets/opening_hours_editor.dart';
import 'package:cut_map/locator.dart';
import 'package:cut_map/models/create_barbershop_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class AddBarbershopSheet extends StatefulWidget {
  const AddBarbershopSheet({super.key});

  @override
  State<AddBarbershopSheet> createState() => _AddBarbershopSheetState();
}

class _AddBarbershopSheetState extends State<AddBarbershopSheet> {
  static const _stepTitles = ['Dados básicos', 'Localização', 'Revisão'];

  final _basicFormKey = GlobalKey<FormState>();
  final _locationFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _controller = locator<AddBarbershopController>();
  int get _step => _controller.state.step;
  LatLng? get _selectedLocation => _controller.state.selectedLocation;
  bool _loadingLocation = false;
  String? _addressLookupMessage;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _phoneController,
      _addressController,
      _numberController,
      _neighborhoodController,
      _cityController,
      _stateController,
    ]) {
      controller.addListener(_refreshButton);
    }
    _controller.addListener(_refreshButton);
  }

  void _refreshButton() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _canContinue => switch (_step) {
    0 =>
      _nameController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty,
    1 =>
      _addressController.text.trim().isNotEmpty &&
          _numberController.text.trim().isNotEmpty &&
          _neighborhoodController.text.trim().isNotEmpty &&
          _cityController.text.trim().isNotEmpty &&
          _stateController.text.trim().length == 2 &&
          _selectedLocation != null,
    _ => _controller.state.hasValidHours,
  };

  Future<void> _next() async {
    if (_step == 0 && !_basicFormKey.currentState!.validate()) return;
    if (_step == 1 && !_locationFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (_step == 2) {
      final created = await _controller.submit(CreateBarbershopRequest(
        name: _nameController.text,
        phone: _phoneController.text,
        description: _descriptionController.text,
        street: _addressController.text,
        number: _numberController.text,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        state: _stateController.text,
        location: _selectedLocation!,
        openingHours: _controller.state.openingHours,
      ));
      if (mounted && created) Navigator.of(context).pop(true);
    } else {
      _controller.setStep(_step + 1);
    }
  }

  Future<void> _chooseLocation() async {
    if (_loadingLocation) return;
    FocusScope.of(context).unfocus();
    setState(() => _loadingLocation = true);
    LatLng? currentLocation;
    String? locationError;
    try {
      currentLocation = await locator<LocationService>().getUserLocation();
    } on LocationServiceException catch (error) {
      locationError = error.message;
    } catch (_) {
      locationError = 'Não foi possível obter sua localização.';
    }
    if (!mounted) return;
    setState(() => _loadingLocation = false);
    final selection = await Navigator.of(context).push<BarbershopLocationSelection>(
      MaterialPageRoute<BarbershopLocationSelection>(
        builder: (_) => BarbershopLocationPicker(
          initialSelection: _selectedLocation,
          initialCenter:
              currentLocation ?? _selectedLocation ?? const LatLng(-23.5505, -46.6333),
          currentLocation: currentLocation,
          initialLocationError: locationError,
        ),
      ),
    );
    if (!mounted || selection == null) return;
    _controller.selectLocation(selection.point);
    final suggestion = selection.address;
    if (suggestion == null) {
      setState(() => _addressLookupMessage =
          'Localização marcada. Preencha o endereço manualmente.');
      return;
    }
    if (suggestion.street != null) _addressController.text = suggestion.street!;
    if (suggestion.number != null) _numberController.text = suggestion.number!;
    if (suggestion.neighborhood != null) {
      _neighborhoodController.text = suggestion.neighborhood!;
    }
    if (suggestion.city != null) _cityController.text = suggestion.city!;
    if (suggestion.stateCode != null) _stateController.text = suggestion.stateCode!;
    setState(() => _addressLookupMessage =
        suggestion.city == null || suggestion.stateCode == null
            ? 'Cidade ou estado não encontrados. Complete o endereço manualmente.'
            : 'Endereço sugerido por OpenStreetMap. Confira os campos antes de salvar.');
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight =
        mediaQuery.size.height - keyboardHeight - mediaQuery.padding.top - 12;
    final sheetHeight = math.min(mediaQuery.size.height * 0.8, availableHeight);

    return PopScope(
      canPop: !_controller.state.isSubmitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SizedBox(
        height: sheetHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.blackDarkGray,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _stepTitles[_step],
                        style: AppFonts.bold16.apply(color: AppColors.white),
                      ),
                    ),
                    IconButton(
                      onPressed: _controller.state.isSubmitting
                          ? null : () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close, color: AppColors.gray),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 7),
                        decoration: BoxDecoration(
                          color: index <= _step
                              ? AppColors.yellow
                              : AppColors.darkGray,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 12),
                  child: switch (_step) {
                    0 => _buildBasicFields(),
                    1 => _buildLocationFields(),
                    _ => _buildReview(),
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  math.max(18.0, mediaQuery.padding.bottom),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.state.error != null) ...[
                      Text(_controller.state.error!,
                          style: AppFonts.regular12.apply(color: AppColors.redSnack)),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        if (_step > 0) ...[
                          Expanded(
                            child: _SheetButton(
                              label: 'Voltar',
                              onTap: _controller.state.isSubmitting
                                  ? null : () => _controller.setStep(_step - 1),
                              primary: false,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _SheetButton(
                            label: _controller.state.isSubmitting
                                ? 'Cadastrando...'
                                : _step == 2 ? 'Cadastrar barbearia' : 'Próximo →',
                            onTap: _canContinue && !_controller.state.isSubmitting
                                ? _next : null,
                            primary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBasicFields() {
    return Form(
      key: _basicFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(
            label: 'Nome da barbearia *',
            hint: 'Ex: Kings Barber',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? 'Informe ao menos 3 caracteres.'
                : null,
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Telefone / WhatsApp *',
            hint: '(11) 99999-0000',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9()\s-]')),
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (value) {
              final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
              return digits.length == 10 || digits.length == 11
                  ? null
                  : 'Informe um telefone com DDD.';
            },
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Descrição',
            hint: 'Conte um pouco sobre sua barbearia...',
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFields() {
    return Form(
      key: _locationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetField(
            label: 'Rua *',
            hint: 'Ex: Rua Augusta',
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Informe a rua.' : null,
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Número *',
            hint: 'Ex: 1234',
            controller: _numberController,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Informe o número.' : null,
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Bairro *',
            hint: 'Seu bairro',
            controller: _neighborhoodController,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Informe o bairro.' : null,
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Cidade *',
            hint: 'Ex: São Paulo',
            controller: _cityController,
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Informe a cidade.' : null,
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Estado (UF) *',
            hint: 'Ex: SP',
            controller: _stateController,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              final state = value?.trim() ?? '';
              return state.length != 2
                  ? 'Use duas letras para o estado.'
                  : null;
            },
          ),
          const SizedBox(height: 24),
          _LocationCard(
            selectedLocation: _selectedLocation,
            isLoading: _loadingLocation,
            loadingMessage: 'Obtendo sua localização...',
            onTap: _loadingLocation ? null : _chooseLocation,
          ),
          if (_addressLookupMessage != null) ...[
            const SizedBox(height: 8),
            Text(_addressLookupMessage!,
                style: AppFonts.regular12.apply(color: AppColors.gray)),
          ],
        ],
      ),
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confira os dados e defina os horários antes de cadastrar.',
          style: AppFonts.regular14.apply(color: AppColors.gray),
        ),
        const SizedBox(height: 22),
        _ReviewItem(label: 'Barbearia', value: _nameController.text.trim()),
        _ReviewItem(label: 'Telefone', value: _phoneController.text.trim()),
        if (_descriptionController.text.trim().isNotEmpty)
          _ReviewItem(
            label: 'Descrição',
            value: _descriptionController.text.trim(),
          ),
        _ReviewItem(label: 'Endereço', value: _addressController.text.trim()),
        _ReviewItem(label: 'Número', value: _numberController.text.trim()),
        _ReviewItem(
          label: 'Bairro',
          value: _neighborhoodController.text.trim(),
        ),
        if (_cityController.text.trim().isNotEmpty)
          _ReviewItem(label: 'Cidade', value: _cityController.text.trim()),
        if (_stateController.text.trim().isNotEmpty)
          _ReviewItem(label: 'Estado', value: _stateController.text.trim()),
        if (_selectedLocation != null)
          _ReviewItem(
            label: 'Localização no mapa',
            value: '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                '${_selectedLocation!.longitude.toStringAsFixed(5)}',
          ),
        const SizedBox(height: 12),
        OpeningHoursEditor(
          hours: _controller.state.openingHours,
          onToggleDay: _controller.toggleDay,
          onChanged: _controller.updateHours,
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.regular12.apply(color: AppColors.gray)),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          cursorColor: AppColors.yellow,
          style: AppFonts.medium14.apply(color: AppColors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.regular14.apply(color: AppColors.gray),
            filled: true,
            fillColor: AppColors.darkGray,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.gray.withValues(alpha: .2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.gray.withValues(alpha: .2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.yellow),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.redSnack),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.redSnack),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: primary ? AppColors.yellow : AppColors.darkGray,
          disabledBackgroundColor: AppColors.darkGray,
          foregroundColor: primary ? AppColors.background : AppColors.gray,
          disabledForegroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(label, style: AppFonts.bold14),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.selectedLocation,
    required this.isLoading,
    required this.loadingMessage,
    required this.onTap,
  });

  final LatLng? selectedLocation;
  final bool isLoading;
  final String loadingMessage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LocationCardPainter(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.yellow,
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.background,
                      size: 17,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  isLoading
                      ? loadingMessage
                      : selectedLocation == null
                      ? 'Localização no mapa'
                      : 'Localização selecionada',
                  style: AppFonts.regular12.apply(color: AppColors.gray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.save();
    canvas.clipRRect(bounds);
    final gridPaint = Paint()
      ..color = AppColors.darkGray.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.restore();

    final borderPaint = Paint()
      ..color = AppColors.darkGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(bounds, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReviewItem extends StatelessWidget {
  const _ReviewItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppFonts.regular12.apply(color: AppColors.gray)),
          const SizedBox(height: 4),
          Text(value, style: AppFonts.medium14.apply(color: AppColors.white)),
        ],
      ),
    );
  }
}
