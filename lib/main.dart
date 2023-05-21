import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const ClientApp());
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus One',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),
      home: const ClientPage(),
    );
  }
}

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ClientPageState createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  TextEditingController ipController = TextEditingController();
  double engineTemperature = 20;
  double tirePressure = 0;
  bool smokeDetector = false;
  Position? currentLocation;
  int numberOfPassengers = 0;

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    final permissionStatus = await Geolocator.checkPermission();
    if (permissionStatus == LocationPermission.denied) {
      final requestedPermissionStatus =
          await Geolocator.requestPermission();
      if (requestedPermissionStatus != LocationPermission.whileInUse &&
          requestedPermissionStatus != LocationPermission.always) {
        // Handle permission denied
        return;
      }
    }

    if (permissionStatus == LocationPermission.deniedForever) {
      // Handle permission denied forever
      return;
    }

    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = position;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error getting location: $error');
      }
    }
  }

  void incrementPassengers() {
    setState(() {
      numberOfPassengers++;
    });
  }

  void decrementPassengers() {
    if (numberOfPassengers > 0) {
      setState(() {
        numberOfPassengers--;
      });
    }
  }

  void sendDataToServer() {
    final ip = ipController.text.trim();

    final socket = IO.io('http://$ip:3000', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.connect();

    socket.onConnect((_) {
      if (kDebugMode) {
        print('Connected to server');
      }
      socket.emit('values', {
        'engineTemperature': engineTemperature,
        'tirePressure': tirePressure,
        'smokeDetector': smokeDetector,
        'latitude': currentLocation?.latitude ?? 0.0,
        'longitude': currentLocation?.longitude ?? 0.0,
        'passengers': numberOfPassengers,
      });
      socket.disconnect();
    });

    // ignore: avoid_print
    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus One'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Enter IP Address',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Engine Temperature: ${engineTemperature.toInt()}°C',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Slider(
              value: engineTemperature,
              min: 20,
              max: 180,
              divisions: 160,
              onChanged: (value) {
                setState(() {
                  engineTemperature = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Tire Pressure: ${tirePressure.toInt()} psi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Slider(
              value: tirePressure,
              min: 0,
              max: 120,
              divisions: 120,
              onChanged: (value) {
                setState(() {
                  tirePressure = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Smoke Detector: ${smokeDetector ? 'Yes' : 'No'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Switch(
              value: smokeDetector,
              onChanged: (value) {
                setState(() {
                  smokeDetector = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'GPS Coordinates: ${currentLocation?.latitude ?? 0.0}, ${currentLocation?.longitude ?? 0.0}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Number of Passengers: $numberOfPassengers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: incrementPassengers,
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  onPressed: decrementPassengers,
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: sendDataToServer,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Send values to server',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}
