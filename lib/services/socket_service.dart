// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String userId;

  SocketService(this.userId) {
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(
      'https://ebb0-140-213-41-133.ngrok-free.app',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'forceNew': true,
      },
    );

    socket.connect();

    socket.onConnect((_) {
      print("Connected to Socket Server");
      socket.emit("user-online", userId);
    });

    socket.onDisconnect((_) {
      print("Disconnected from Socket Server");
    });

    socket.on("update-user-status", (data) {
      print("Online users: $data");
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
