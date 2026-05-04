/// Lifecycle states of the realtime socket. UI/diagnostics layer can
/// listen on the status stream and react (e.g. show a "reconnecting"
/// banner) without poking at the underlying transport.
enum SocketConnectionStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  disconnected,
  error,
}
