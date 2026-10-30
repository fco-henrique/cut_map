import 'package:cut_map/common/constants/app_colors.dart';
import 'package:cut_map/common/constants/app_fonts.dart';
import 'package:cut_map/common/extensions/sizes.dart';
import 'package:cut_map/features/barbershops/controllers/barbershops_controller.dart';
import 'package:cut_map/features/barbershops/states/barbershops_state.dart';
import 'package:cut_map/features/barbershops/widgets/add_barbershop_sheet.dart';
import 'package:cut_map/features/barbershops/widgets/barbershop_management_card.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class BarbershopsScreen extends StatefulWidget {
  const BarbershopsScreen({super.key});

  @override
  State<BarbershopsScreen> createState() => _BarbershopsScreenState();
}

class _BarbershopsScreenState extends State<BarbershopsScreen> {
  final _controller = locator<BarbershopsController>();
  bool _showOwned = true;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _showOwned
          ? FloatingActionButton(
              onPressed: _openAddBarbershopSheet,
              tooltip: 'Adicionar barbearia',
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            final items = state is BarbershopsLoaded ? state.items : null;
            final owned = items?.where((item) => item.memberRole == 'OWNER').toList();
            final employed = items?.where((item) => item.memberRole != 'OWNER').toList();
            final visible = _showOwned ? owned : employed;
            return RefreshIndicator(
              onRefresh: _controller.load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildRoleSelector(owned?.length ?? 0, employed?.length ?? 0),
                    const SizedBox(height: 20),
                    if (state is BarbershopsLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state is BarbershopsFailure)
                      Column(children: [
                        Text(state.message, style: AppFonts.regular14.apply(color: AppColors.white)),
                        TextButton(onPressed: _controller.load, child: const Text('Tentar novamente')),
                      ])
                    else if (visible?.isEmpty == true)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _showOwned ? 'Você ainda não cadastrou barbearias.'
                              : 'Você ainda não participa de barbearias como barbeiro.',
                          style: AppFonts.regular14.apply(color: AppColors.gray),
                        ),
                      )
                    else if (visible != null)
                      for (final item in visible) ...[
                        BarbershopManagementCard(
                          barbershop: item,
                          isOwner: _showOwned,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(
          "Barbearias",
          style: AppFonts.extraBold24.apply(color: AppColors.white),
        ),
        const SizedBox(height: 4),
        Text(
          "Seus estabelecimentos",
          style: AppFonts.regular14.apply(color: AppColors.gray),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(int ownerCount, int employeeCount) {
    return Container(
      height: 50.h,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.blackDarkGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleTab(
              label: 'Proprietário',
              icon: Symbols.crown,
              count: ownerCount,
              selected: _showOwned,
              onTap: () => setState(() => _showOwned = true),
            ),
          ),
          Expanded(
            child: _RoleTab(
              label: 'Barbeiro',
              icon: Icons.work_outline,
              count: employeeCount,
              selected: !_showOwned,
              onTap: () => setState(() => _showOwned = false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddBarbershopSheet() async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const AddBarbershopSheet(),
    );
    if (!mounted || completed != true) return;

    await _controller.load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barbearia cadastrada com sucesso.'),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? AppColors.background : AppColors.gray;

    return SizedBox.expand(
      child: Material(
        color: selected ? AppColors.yellow : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: foreground),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selected
                      ? AppFonts.bold14.apply(color: foreground)
                      : AppFonts.regular14.apply(color: foreground),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.background.withValues(alpha: 0.16)
                      : AppColors.darkGray,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
