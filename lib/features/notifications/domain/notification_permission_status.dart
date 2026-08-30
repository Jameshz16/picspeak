/// Permission status for notification permissions.
///
/// Relocated from data layer to domain layer to maintain clean architecture
/// boundaries: domain must not depend on data.
enum NotificationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
}
