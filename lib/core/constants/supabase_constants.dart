// PROTOTYPE ASSUMPTION: Supabase credentials are stored here as placeholder.
// Replace with actual values from your Supabase project dashboard.
// NEVER commit real production keys to a public repository.
class SupabaseConstants {
  static const String supabaseUrl = 'https://jlxughgzynyspaeouxlx.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_JFw9EC4Sy8XcUmCvHgG5Fg_WGcEKA_j';

  // Table names
  static const String usersTable = 'users';
  static const String serviceCentersTable = 'service_centers';
  static const String servicesTable = 'services';
  static const String countersTable = 'counters';
  static const String queuesTable = 'queues';
  static const String queueEntriesTable = 'queue_entries';
  static const String queueEventsTable = 'queue_events';
  static const String serviceSessionsTable = 'service_sessions';
  static const String ewtStatsTable = 'ewt_stats';
}
