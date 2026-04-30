import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurements.dart';
import 'package:tryzeon/core/shared/measurements/presentation/mappers/measurement_type_ui_mapper.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/validators.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:typed_result/typed_result.dart';

class BodyMeasurementsSettingsPage extends HookConsumerWidget {
  const BodyMeasurementsSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('編輯身形資料', style: textTheme.headlineMedium),
                        Text('更新您的身形量測數據', style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: profileAsync.when(
                data: (final profile) {
                  if (profile == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return _BodyMeasurementsForm(profile: profile);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (final error, final stack) => ErrorView(
                  message: error.displayMessage(context),
                  onRetry: () => refreshUserProfile(ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyMeasurementsForm extends HookConsumerWidget {
  const _BodyMeasurementsForm({required this.profile});

  final UserProfile profile;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);

    final measurementControllers = <MeasurementType, TextEditingController>{};
    for (final type in MeasurementType.values) {
      measurementControllers[type] = useTextEditingController(
        text: profile.measurements?[type]?.toString() ?? '',
      );
    }

    final isLoading = useState(false);
    var hasChanges = false;

    for (final type in MeasurementType.values) {
      final currentValue = useValueListenable(measurementControllers[type]!).text;
      final originalValue = profile.measurements?[type]?.toString() ?? '';
      final currentDouble = double.tryParse(currentValue);
      final originalDouble = double.tryParse(originalValue);

      if (currentDouble != originalDouble) {
        hasChanges = true;
      }
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> updateMeasurements() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      final measurementsJson = <String, dynamic>{
        for (final entry in measurementControllers.entries)
          entry.key.value: double.tryParse(entry.value.text),
      };

      final Measurements newMeasurements = Measurements.fromJson(measurementsJson);

      final updateUseCase = ref.read(updateUserBodyMeasurementsUseCaseProvider);
      final result = await updateUseCase(measurements: newMeasurements);

      if (!context.mounted) return;

      isLoading.value = false;

      if (result.isSuccess) {
        TopNotification.show(context, message: '身形資料已更新', type: NotificationType.success);

        if (context.mounted) Navigator.pop(context);

        Future.delayed(const Duration(milliseconds: 100), () {
          ref.invalidate(userProfileProvider);
        });
      } else {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
          type: NotificationType.error,
        );
      }
    }

    Widget buildTextField({
      required final TextEditingController controller,
      required final String label,
      required final IconData icon,
      final TextInputType? keyboardType,
      final List<TextInputFormatter>? inputFormatters,
      final String? Function(String?)? validator,
    }) {
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: colorScheme.primary),
        ),
        validator: validator,
      );
    }

    Widget buildSectionCard({
      required final IconData icon,
      required final String title,
      required final List<Widget> children,
    }) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: Icon(icon, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(title, style: textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '資料僅供試穿尺寸推薦，不對外顯示。',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.sm),

            buildSectionCard(
              icon: Icons.straighten_rounded,
              title: '身形資料',
              children: [
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: MeasurementType.values.map((final type) {
                    return SizedBox(
                      width:
                          (MediaQuery.of(context).size.width -
                              (AppSpacing.lg * 2) -
                              (AppSpacing.lg * 2) -
                              AppSpacing.md) /
                          2,
                      child: buildTextField(
                        controller: measurementControllers[type]!,
                        label: type.label,
                        icon: type.icon,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: AppValidators.validateMeasurement,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading.value || !hasChanges ? null : updateMeasurements,
                child: isLoading.value
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, size: 24),
                          SizedBox(width: AppSpacing.sm),
                          Text('儲存'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
