import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/presentation_spacing.dart';

/// Product Contribution Widget
///
/// Allows brands to specify product contributions for sponsorships.
/// Tracks product name, quantity, and value.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class ProductContributionWidget extends StatefulWidget {
  final String? productName;
  final int productQuantity;
  final double? productValue;
  final ValueChanged<String>? onProductNameChanged;
  final ValueChanged<int>? onQuantityChanged;
  final ValueChanged<double>? onUnitPriceChanged;

  const ProductContributionWidget({
    super.key,
    this.productName,
    this.productQuantity = 1,
    this.productValue,
    this.onProductNameChanged,
    this.onQuantityChanged,
    this.onUnitPriceChanged,
  });

  @override
  State<ProductContributionWidget> createState() =>
      _ProductContributionWidgetState();
}

class _ProductContributionWidgetState extends State<ProductContributionWidget> {
  late TextEditingController _productNameController;
  late TextEditingController _unitPriceController;
  late int _quantity;
  double? _unitPrice;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.productName);
    _unitPriceController = TextEditingController(
      text: widget.productValue != null && widget.productQuantity > 0
          ? (widget.productValue! / widget.productQuantity).toStringAsFixed(2)
          : null,
    );
    _quantity = widget.productQuantity;
    _unitPrice = widget.productValue != null && widget.productQuantity > 0
        ? widget.productValue! / widget.productQuantity
        : null;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _unitPrice != null ? _unitPrice! * _quantity : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kSpaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Contribution',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                hintText: 'Premium Olive Oil',
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.inventory_2,
                    color: AppColors.textSecondary),
              ),
              onChanged: (value) {
                widget.onProductNameChanged?.call(value);
              },
            ),
            const SizedBox(height: 16),

            // Quantity
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () {
                              setState(() {
                                _quantity--;
                                widget.onQuantityChanged?.call(_quantity);
                                _updateTotalValue();
                              });
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: _quantity > 1
                            ? AppTheme.primaryColor
                            : AppColors.grey400,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceMd, vertical: kSpaceXs),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_quantity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _quantity++;
                          widget.onQuantityChanged?.call(_quantity);
                          _updateTotalValue();
                        });
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Unit Price
            TextFormField(
              controller: _unitPriceController,
              decoration: InputDecoration(
                labelText: 'Unit Price (Retail)',
                hintText: '25.00',
                prefixText: '\$',
                filled: true,
                fillColor: AppColors.grey100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money,
                    color: AppColors.textSecondary),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _unitPrice = double.tryParse(value);
                _updateTotalValue();
              },
            ),
            const SizedBox(height: 16),

            // Total Value
            if (totalValue != null) ...[
              Container(
                padding: const EdgeInsets.all(kSpaceSm),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Product Value',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      '\$${totalValue.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateTotalValue() {
    if (_unitPrice != null) {
      // ignore: unused_local_variable - Reserved for future total display
      final total = _unitPrice! * _quantity;
      widget.onUnitPriceChanged?.call(_unitPrice!);
    }
  }
}
