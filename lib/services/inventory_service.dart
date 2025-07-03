import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_product.dart';

class InventoryService {
  static final _supabase = Supabase.instance.client;

  /// Updates inventory quantities by subtracting the used quantities
  /// This should only be called when creating new invoices, not when editing
  static Future<void> updateInventoryQuantities(
    List<InvoiceProduct> products,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    for (final product in products) {
      if (product.inventoryId.isNotEmpty) {
        await _updateSingleProductInventory(product, userId);
      }
    }
  }

  /// Updates inventory for a single product
  static Future<void> _updateSingleProductInventory(
    InvoiceProduct product,
    String userId,
  ) async {
    try {
      // Determine the correct table based on inventory type
      final tableName =
          product.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Get current quantity
      final currentInventoryResponse =
          await _supabase
              .from(tableName)
              .select('quantity_available')
              .eq('id', product.inventoryId)
              .eq('tenant_id', userId)
              .single();

      final currentQuantity =
          (currentInventoryResponse['quantity_available'] as num?)
              ?.toDouble() ??
          0.0;
      final newQuantity = currentQuantity - product.quantity;

      // Update the inventory with the new quantity
      await _supabase
          .from(tableName)
          .update({'quantity_available': newQuantity})
          .eq('id', product.inventoryId)
          .eq('tenant_id', userId);
    } catch (e) {
      // Log the error and rethrow to notify the caller
      print('Error updating inventory for product ${product.inventoryId}: $e');
      rethrow;
    }
  }

  /// Restores inventory quantities (for canceling invoices or returns)
  /// This adds back the quantities to inventory
  static Future<void> restoreInventoryQuantities(
    List<InvoiceProduct> products,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    for (final product in products) {
      if (product.inventoryId.isNotEmpty) {
        await _restoreSingleProductInventory(product, userId);
      }
    }
  }

  /// Restores inventory for a single product
  static Future<void> _restoreSingleProductInventory(
    InvoiceProduct product,
    String userId,
  ) async {
    try {
      // Determine the correct table based on inventory type
      final tableName =
          product.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Get current quantity
      final currentInventoryResponse =
          await _supabase
              .from(tableName)
              .select('quantity_available')
              .eq('id', product.inventoryId)
              .eq('tenant_id', userId)
              .single();

      final currentQuantity =
          (currentInventoryResponse['quantity_available'] as num).toDouble();
      final newQuantity = currentQuantity + product.quantity;

      // Update the inventory quantity
      await _supabase
          .from(tableName)
          .update({'quantity_available': newQuantity})
          .eq('id', product.inventoryId)
          .eq('tenant_id', userId);
    } catch (e) {
      throw Exception('Error restoring inventory for ${product.name}: $e');
    }
  }

  /// Checks if there's sufficient inventory for all products
  static Future<bool> checkInventoryAvailability(
    List<InvoiceProduct> products,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    for (final product in products) {
      if (product.inventoryId.isNotEmpty) {
        final isAvailable = await _checkSingleProductAvailability(
          product,
          userId,
        );
        if (!isAvailable) {
          return false;
        }
      }
    }
    return true;
  }

  /// Checks availability for a single product
  static Future<bool> _checkSingleProductAvailability(
    InvoiceProduct product,
    String userId,
  ) async {
    try {
      // Determine the correct table based on inventory type
      final tableName =
          product.inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Get current quantity
      final currentInventoryResponse =
          await _supabase
              .from(tableName)
              .select('quantity_available')
              .eq('id', product.inventoryId)
              .eq('tenant_id', userId)
              .single();

      final currentQuantity =
          (currentInventoryResponse['quantity_available'] as num).toDouble();

      return currentQuantity >= product.quantity;
    } catch (e) {
      return false;
    }
  }

  /// Gets the available quantity for a specific inventory item
  static Future<double> getAvailableQuantity(
    String inventoryId,
    String inventoryType,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Determine the correct table based on inventory type
      final tableName =
          inventoryType == 'fabric'
              ? 'fabric_inventory'
              : 'accessories_inventory';

      // Get current quantity
      final currentInventoryResponse =
          await _supabase
              .from(tableName)
              .select('quantity_available')
              .eq('id', inventoryId)
              .eq('tenant_id', userId)
              .single();

      return (currentInventoryResponse['quantity_available'] as num).toDouble();
    } catch (e) {
      return 0.0;
    }
  }
}
