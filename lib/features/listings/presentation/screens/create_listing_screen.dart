import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusehub/core/constants/app_constants.dart';
import 'package:reusehub/core/constants/app_theme.dart';
import 'package:reusehub/features/auth/data/auth_repository.dart';
import 'package:reusehub/features/listings/data/listings_repository.dart';
import 'package:reusehub/shared/models/listing.dart';
import 'package:reusehub/shared/widgets/app_button.dart';
import 'package:reusehub/shared/widgets/app_snackbar.dart';
import 'package:reusehub/shared/widgets/app_text_field.dart';



class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _selectedCategory = AppConstants.categories.first;
  ListingCondition _selectedCondition = ListingCondition.good;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 75);
    if (images.isNotEmpty) {
      setState(() => _selectedImages = images.take(5).toList());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      AppSnackbar.error(context, 'You must be signed in to list an item.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(listingsRepositoryProvider);
      List<String> imageUrls = [];

      if (_selectedImages.isNotEmpty) {
        imageUrls = await repo.uploadImages(_selectedImages, currentUser.id);
      }

      final listing = Listing(
        id: '',
        sellerId: currentUser.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.replaceAll(',', '')),
        category: _selectedCategory,
        condition: _selectedCondition,
        images: imageUrls,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        quantity: int.tryParse(_quantityController.text) ?? 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final created = await repo.createListing(listing);

      // Promote user to seller on first listing
      final profile = await ref.read(authRepositoryProvider).getProfile(currentUser.id);
      if (profile != null && !profile.isSeller) {
        await ref.read(authRepositoryProvider).upsertProfile(
              profile.copyWith(isSeller: true),
            );
      }

      if (mounted) {
        AppSnackbar.success(context, 'Listing published.');
        context.go('/listings/${created.id}');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to create listing: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        title: const Text('New listing'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text('Photos', style: AppTypography.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Up to 5 photos. First photo is the cover.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            _ImagePickerRow(
              images: _selectedImages,
              onPickImages: _pickImages,
              onRemove: (i) => setState(() => _selectedImages.removeAt(i)),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g. Reclaimed oak floorboards',
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 5) return 'At least 5 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe the material: dimensions, origin, defects, usage...',
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description is required';
                if (v.trim().length < 20) return 'At least 20 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _priceController,
              label: 'Price (Rp)',
              hint: '0 for free',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Price is required';
                final num = double.tryParse(v.replaceAll(',', ''));
                if (num == null || num < 0) return 'Enter a valid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _DropdownField<String>(
              label: 'Category',
              value: _selectedCategory,
              items: AppConstants.categories,
              itemLabel: (c) => c,
              onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
            ),
            const SizedBox(height: 16),
            _DropdownField<ListingCondition>(
              label: 'Condition',
              value: _selectedCondition,
              items: ListingCondition.values,
              itemLabel: (c) => c.label,
              onChanged: (v) => setState(() => _selectedCondition = v ?? _selectedCondition),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _quantityController,
              label: 'Quantity',
              hint: '1',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null || int.parse(v) < 1) return 'Min 1';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _locationController,
              label: 'Location (optional)',
              hint: 'e.g. Jakarta Selatan',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Publish listing',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerRow extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemove;

  const _ImagePickerRow({
    required this.images,
    required this.onPickImages,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (images.length < 5)
            GestureDetector(
              onTap: onPickImages,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.borderMedium),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.warmGrey, size: 28),
                    SizedBox(height: 4),
                    Text(
                      'Add photos',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.warmGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...images.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      image: DecorationImage(
                        image: FileImage(File(e.value.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.inkBlack,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (e.key == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ember.withValues(alpha: 0.85),
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Text(
                          'Cover',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              )),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          borderRadius: AppRadius.md,
        ),
      ],
    );
  }
}
