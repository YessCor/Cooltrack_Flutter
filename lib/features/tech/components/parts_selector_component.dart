import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class PartItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final bool isSelected;
  final int quantity;

  PartItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.isSelected = false,
    this.quantity = 1,
  });

  PartItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    bool? isSelected,
    int? quantity,
  }) {
    return PartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isSelected: isSelected ?? this.isSelected,
      quantity: quantity ?? this.quantity,
    );
  }
}

class PartsSelectorComponent extends StatefulWidget {
  final List<PartItem> initialParts;
  final Function(List<PartItem>) onPartsChanged;

  const PartsSelectorComponent({
    super.key,
    this.initialParts = const [],
    required this.onPartsChanged,
  });

  @override
  State<PartsSelectorComponent> createState() => _PartsSelectorComponentState();
}

class _PartsSelectorComponentState extends State<PartsSelectorComponent> {
  List<PartItem> _parts = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<PartItem> _availableParts = [
    PartItem(id: '1', name: 'Filtro de aire', price: 150.00),
    PartItem(id: '2', name: 'Capacitor 25/5', price: 350.00),
    PartItem(id: '3', name: 'Capacitor 35/5', price: 380.00),
    PartItem(id: '4', name: 'Contactor', price: 450.00),
    PartItem(id: '5', name: 'Termostato', price: 650.00),
    PartItem(id: '6', name: 'Motor ventilado', price: 1200.00),
    PartItem(id: '7', name: 'Compresor', price: 3500.00),
    PartItem(id: '8', name: 'Sensor de temperatura', price: 280.00),
    PartItem(id: '9', name: 'Válvula de expansión', price: 890.00),
    PartItem(id: '10', name: 'Tubo de cobre 1/4"', price: 120.00),
    PartItem(id: '11', name: 'Tubo de cobre 3/8"', price: 180.00),
    PartItem(id: '12', name: 'Aislamiento térmico', price: 95.00),
  ];

  @override
  void initState() {
    super.initState();
    _parts = List.from(widget.initialParts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PartItem> get _filteredParts {
    if (_searchQuery.isEmpty) return _availableParts;
    return _availableParts
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _addPart(PartItem part) {
    final existingIndex = _parts.indexWhere((p) => p.id == part.id);
    if (existingIndex >= 0) {
      setState(() {
        _parts[existingIndex] = _parts[existingIndex].copyWith(
          quantity: _parts[existingIndex].quantity + 1,
        );
      });
    } else {
      setState(() {
        _parts.add(part.copyWith(isSelected: true));
      });
    }
    widget.onPartsChanged(_parts);
  }

  void _removePart(String partId) {
    setState(() {
      _parts.removeWhere((p) => p.id == partId);
    });
    widget.onPartsChanged(_parts);
  }

  void _updateQuantity(String partId, int delta) {
    setState(() {
      final index = _parts.indexWhere((p) => p.id == partId);
      if (index >= 0) {
        final newQty = _parts[index].quantity + delta;
        if (newQty <= 0) {
          _parts.removeAt(index);
        } else {
          _parts[index] = _parts[index].copyWith(quantity: newQty);
        }
      }
    });
    widget.onPartsChanged(_parts);
  }

  double get _total => _parts.fold(0, (sum, p) => sum + (p.price * p.quantity));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Refacciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_parts.isNotEmpty)
              Text(
                'Total: \$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_parts.isNotEmpty) ...[
          _buildSelectedParts(),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Buscar refacción...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        _buildAvailableParts(),
      ],
    );
  }

  Widget _buildSelectedParts() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seleccionadas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ..._parts.map((part) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    part.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 20,
                  onPressed: () => _updateQuantity(part.id, -1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${part.quantity}'),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 20,
                  onPressed: () => _updateQuantity(part.id, 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${(part.price * part.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removePart(part.id),
                  child: Icon(Icons.close, size: 18, color: AppColors.error),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAvailableParts() {
    final filtered = _filteredParts;

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron refacciones',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final part = filtered[index];
        final isInCart = _parts.any((p) => p.id == part.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(part.name),
            subtitle: Text('\$${part.price.toStringAsFixed(2)}'),
            trailing: isInCart
                ? Icon(Icons.check_circle, color: AppColors.success)
                : IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _addPart(part),
                  ),
            onTap: isInCart ? null : () => _addPart(part),
          ),
        );
      },
    );
  }
}