import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connectToServer(Function(dynamic) onScanReceived) {
    // Connect to your Node.js backend
    socket = IO.io('http://192.168.101.73:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) => print('SocketService: Connected to server'));
    socket.onConnectError((data) => print('SocketService: Connection Error: $data'));

    // Listen for the event sent by your Node.js backend when the IoT device scans
    socket.on('new_item_scanned', (data) {
      onScanReceived(data);
    });
  }
}