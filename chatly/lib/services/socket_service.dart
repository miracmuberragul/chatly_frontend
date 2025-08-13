import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // IMPORTANT: Replace with your server's local IP address.
  // Make sure your computer and test device are on the same Wi-Fi network.
  static const String _serverUrl =
      'ws://192.168.1.59:8080/'; // Use your actual server IP

  WebSocketChannel? _channel;
  String? _userId;
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // Expose the stream for other parts of the app to listen to incoming events.
  Stream<Map<String, dynamic>> get events => _eventController.stream;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  bool _isConnecting = false;

  /// Connects to the WebSocket server with automatic reconnection.
  void connect(String userId) {
    if (_isConnecting) {
      debugPrint('SocketService: Connection attempt already in progress.');
      return;
    }

    // Avoid creating multiple connections if already connected.
    if (_channel != null && _channel!.closeCode == null) {
      debugPrint('SocketService: Already connected.');
      return;
    }

    _isConnecting = true;
    _userId = userId; // Store the user ID
    debugPrint(
      'SocketService: Connecting to WebSocket server for user $_userId...',
    );

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(_serverUrl),
        protocols: null,
      );

      // Listen for incoming messages from the server.
      _channel!.stream.listen(
        (message) {
          _reconnectAttempts = 0; // Reset on successful message
          _isConnecting = false;
          try {
            final decodedMessage = jsonDecode(message);
            if (decodedMessage is Map<String, dynamic>) {
              // Add the decoded message to our stream for listeners.
              _eventController.add(decodedMessage);
            }
          } catch (e) {
            debugPrint('SocketService: Could not decode message: $e');
          }
        },
        onDone: () {
          _isConnecting = false;
          debugPrint('SocketService: Connection closed.');
          _channel = null;
          _attemptReconnect();
        },
        onError: (error) {
          _isConnecting = false;
          debugPrint('SocketService: Error: $error');
          _channel = null;
          _attemptReconnect();
        },
      );

      // Send initial events after a short delay to ensure connection is established
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_channel != null && _channel!.closeCode == null) {
          debugPrint(
            'SocketService: Connection established, sending user_online event',
          );
          sendEvent('user_online', {'userId': _userId});
          _isConnecting = false;
        }
      });
    } catch (e) {
      _isConnecting = false;
      debugPrint('SocketService: Connection failed: $e');
      _attemptReconnect();
    }
  }

  /// Attempts to reconnect with exponential backoff.
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint(
        'SocketService: Max reconnection attempts reached. Giving up.',
      );
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: _reconnectAttempts * 2,
    ); // Exponential backoff
    debugPrint(
      'SocketService: Attempting reconnection in ${delay.inSeconds} seconds (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    Future.delayed(delay, () {
      if (_userId != null) {
        connect(_userId!);
      }
    });
  }

  /// Sends a structured event to the server.
  void sendEvent(String eventType, Map<String, dynamic> data) {
    log(
      'sendEvent',
      name: 'SocketService',
      error: {'event': eventType, 'data': data},
    );
    if (_channel == null || _channel!.closeCode != null) {
      debugPrint('SocketService: Cannot send event, not connected.');
      return;
    }
    final message = jsonEncode({'event': eventType, ...data});
    _channel!.sink.add(message);
    debugPrint('SocketService: Sent event -> $message');
  }

  /// Disposes the connection and stream controller.
  void dispose() {
    if (_userId != null) {
      // Announce that the user is going offline before disconnecting.
      sendEvent('user_offline', {'userId': _userId});
    }
    _channel?.sink.close();
    _eventController.close();
    debugPrint('SocketService: Disposed.');
  }
}
