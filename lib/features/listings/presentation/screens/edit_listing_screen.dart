import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../features/listings/data/listings_repository.dart';
import '../../../../shared/models/listing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/app_text_field.dart';



class EditListingScreen extends ConsumerStatefulWidget {
  final String listingId;

  const EditListingScreen({super.key, required this.listingId});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  String? _selectedCategory;
  ListingCondition? _selectedCondition;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _initFromListing(Listing listing) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = listing.title;
    _descriptionController.text = listing.description;
    _priceController.text = listing.price.toStringAsFixed(0);
    _locationController.text = listing.location ?? '';
    _quantityController.text = listing.quantity.toString();
    _selectedCategory = listing.category;
    _selectedCondition = listing.condition;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(listingsRepositoryProvider).updateListing(
        widget.listingId,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'price': double.parse(_priceController.text.replaceAll(',', '')),
          'category': _selectedCategory,
          'condition': _selectedCondition?.value,
          'quantity': int.tryParse(_quantityController.text) ?? 1,
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        },
      );

      ref.invalidate(listingDetailProvider(widget.listingId));

      if (mounted) {
        AppSnackbar.success(context, 'Listing updated.');
        context.pop();
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text('This cannot be undone. Delete this listing?'),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(listingsRepositoryProvider).deleteListing(widget.listingId);
      if (mounted) {
        AppSnackbar.success(context, 'Listing deleted.');
        context.go('/');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to delete: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(listingDetailProvider(widget.listingId));

    return listingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Edit listing')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (listing) {
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Edit listing')),
            body: const Center(child: Text('Listing not found.')),
          );
        }
        _initFromListing(listing);

        return Scaffold(
          backgroundColor: AppColors.warmWhite,
          appBar: AppBar(
            title: const Text('Edit listing'),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: _delete,
                tooltip: 'Delete listing',
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _priceController,
                  label: 'Price (Rp)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v.replaceAll(',', '')) == null) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _dropdownField<String>(
                  label: 'Category',
                  value: _selectedCategory ?? listing.category,
                  items: AppConstants.categories,
                  itemLabel: (c) => c,
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 16),
                _dropdownField<ListingCondition>(
                  label: 'Condition',
                  value: _selectedCondition ?? listing.condition,
                  items: ListingCondition.values,
                  itemLabel: (c) => c.label,
                  onChanged: (v) => setState(() => _selectedCondition = v),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationController,
                  label: 'Location (optional)',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Save changes',
                  onPressed: _save,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: AppColors.charcoal, letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
              .toList(),
          onChanged: onChanged,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.inkBlack),
          decoration: const InputDecoration(),
          dropdownColor: AppColors.warmWhite,
        ),
      ],
    );
  }
}
