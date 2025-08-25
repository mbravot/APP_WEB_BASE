import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SucursalSelector extends StatelessWidget {
  final String? selectedSucursal;
  final List<String> sucursales;
  final Function(String?) onChanged;

  const SucursalSelector({
    super.key,
    this.selectedSucursal,
    required this.sucursales,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Sucursal:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: selectedSucursal,
            onChanged: onChanged,
            items: sucursales.map((sucursal) {
              return DropdownMenuItem<String>(
                value: sucursal,
                child: Text(
                  sucursal,
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
            underline: Container(),
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
