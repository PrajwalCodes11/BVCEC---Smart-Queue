import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/errors/app_exception.dart';
import '../models/service_center.dart';
import '../models/service.dart';

class ServiceRepository {
  final SupabaseClient _client;
  ServiceRepository(this._client);

  Future<List<ServiceCenter>> getActiveServiceCenters() async {
    try {
      final data = await _client
          .from(SupabaseConstants.serviceCentersTable)
          .select()
          .eq('is_active', true)
          .order('name');
      return (data as List)
          .map((e) => ServiceCenter.fromJson(_normalize(e)))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load service centers: $e');
    }
  }

  Future<List<ServiceCenter>> getAllServiceCenters() async {
    try {
      final data = await _client
          .from(SupabaseConstants.serviceCentersTable)
          .select()
          .order('name');
      return (data as List)
          .map((e) => ServiceCenter.fromJson(_normalize(e)))
          .toList();
    } catch (e) {
      throw NetworkException('Failed to load service centers: $e');
    }
  }

  Future<ServiceCenter> createServiceCenter({
    required String name,
    required String description,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.serviceCentersTable)
          .insert({'name': name, 'description': description, 'is_active': true})
          .select()
          .single();
      return ServiceCenter.fromJson(_normalize(data));
    } catch (e) {
      throw NetworkException('Failed to create service center: $e');
    }
  }

  Future<void> updateServiceCenter(ServiceCenter center) async {
    try {
      await _client
          .from(SupabaseConstants.serviceCentersTable)
          .update({
            'name': center.name,
            'description': center.description,
            'is_active': center.isActive,
          })
          .eq('id', center.id);
    } catch (e) {
      throw NetworkException('Failed to update service center: $e');
    }
  }

  Future<void> deleteServiceCenter(String centerId) async {
    try {
      // 1. Delete associated counters
      await _client
          .from(SupabaseConstants.countersTable)
          .delete()
          .eq('service_center_id', centerId);

      // 2. Delete associated services
      await _client
          .from(SupabaseConstants.servicesTable)
          .delete()
          .eq('service_center_id', centerId);

      // 3. Delete queues for this center
      await _client
          .from(SupabaseConstants.queuesTable)
          .delete()
          .eq('service_center_id', centerId);

      // 4. Delete the service center
      await _client
          .from(SupabaseConstants.serviceCentersTable)
          .delete()
          .eq('id', centerId);
    } catch (e) {
      throw NetworkException('Failed to delete service center: $e');
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _client
          .from(SupabaseConstants.servicesTable)
          .delete()
          .eq('id', serviceId);
    } catch (e) {
      throw NetworkException('Failed to delete service: $e');
    }
  }

  Future<List<Service>> getServicesForCenter(String serviceCenterId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.servicesTable)
          .select()
          .eq('service_center_id', serviceCenterId)
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => Service.fromJson(_normalize(e))).toList();
    } catch (e) {
      throw NetworkException('Failed to load services: $e');
    }
  }

  /// Returns all active services across the entire campus
  Future<List<Service>> getAllActiveServices() async {
    try {
      final data = await _client
          .from(SupabaseConstants.servicesTable)
          .select()
          .eq('is_active', true)
          .order('name');
      return (data as List).map((e) => Service.fromJson(_normalize(e))).toList();
    } catch (e) {
      throw NetworkException('Failed to load all active services: $e');
    }
  }

  /// Returns all services across the entire campus (active + inactive for Admin)
  Future<List<Service>> getAllServices() async {
    try {
      final data = await _client
          .from(SupabaseConstants.servicesTable)
          .select()
          .order('name');
      return (data as List).map((e) => Service.fromJson(_normalize(e))).toList();
    } catch (e) {
      throw NetworkException('Failed to load all services: $e');
    }
  }

  Future<List<Service>> getAllServicesForCenter(String serviceCenterId) async {
    try {
      final data = await _client
          .from(SupabaseConstants.servicesTable)
          .select()
          .eq('service_center_id', serviceCenterId)
          .order('name');
      return (data as List).map((e) => Service.fromJson(_normalize(e))).toList();
    } catch (e) {
      throw NetworkException('Failed to load services: $e');
    }
  }

  Future<Service> createService({
    required String serviceCenterId,
    required String name,
    required String description,
    required int estimatedDurationMinutes,
  }) async {
    try {
      final data = await _client
          .from(SupabaseConstants.servicesTable)
          .insert({
            'service_center_id': serviceCenterId,
            'name': name,
            'description': description,
            'estimated_duration_minutes': estimatedDurationMinutes,
            'is_active': true,
          })
          .select()
          .single();
      return Service.fromJson(_normalize(data));
    } catch (e) {
      throw NetworkException('Failed to create service: $e');
    }
  }

  Future<void> updateService(Service service) async {
    try {
      await _client
          .from(SupabaseConstants.servicesTable)
          .update({
            'name': service.name,
            'description': service.description,
            'estimated_duration_minutes': service.estimatedDurationMinutes,
            'is_active': service.isActive,
          })
          .eq('id', service.id);
    } catch (e) {
      throw NetworkException('Failed to update service: $e');
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      final camelKey = _toCamel(key);
      result[camelKey] = value;
    });
    return result;
  }

  String _toCamel(String snake) {
    final parts = snake.split('_');
    if (parts.length == 1) return snake;
    return parts[0] +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
