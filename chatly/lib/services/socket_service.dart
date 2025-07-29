import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  // IMPORTANT: Replace with your server's local IP address.
  // Make sure your computer and test device are on the same Wi-Fi network.
  static const String _serverUrl = 'ws://192.168.1.59:8080'; // Use your actual server IP

  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  // Expose the stream for other parts of the app to listen to incoming events.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  /// Connects to the WebSocket server.
  void connect(String userId) {
    // Avoid creating multiple connections if already connected.
    if (_channel != null && _channel!.closeCode == null) {
      print('SocketService: Already connected.');
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      print('SocketService: Connecting to WebSocket server...');

      // Listen for incoming messages from the server.
      _channel!.stream.listen(
        (message) {
          try {
            final decodedMessage = jsonDecode(message);
            if (decodedMessage is Map<String, dynamic>) {
              // Add the decoded message to our stream for listeners.
              _eventController.add(decodedMessage);
            }
          } catch (e) {
            print('SocketService: Could not decode message: $e');
          }
        },
        onDone: () {
          print('SocketService: Connection closed.');
          // Here you could implement reconnection logic if desired.
        },
        onError: (error) {
          print('SocketService: Error: $error');
          // Handle error, maybe try to reconnect.
        },
      );
    } catch (e) {
      print('SocketService: Error on connection: $e');
    }
  }

  /// Sends a structured event to the server.
  void sendEvent(String eventType, Map<String, dynamic> data) {
    if (_channel == null || _channel!.closeCode != null) {
      print('SocketService: Cannot send event, not connected.');
      return;
    }
    final message = jsonEncode({'event': eventType, ...data});
    _channel!.sink.add(message);
    print('SocketService: Sent event -> $message');
  }

  /// Disposes the connection and stream controller.
  void dispose() {
    _channel?.sink.close();
    _eventController.close();
    print('SocketService: Disposed.');
  }
}
