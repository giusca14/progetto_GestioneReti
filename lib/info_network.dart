import 'package:flutter/material.dart';
import 'network_service.dart';

class InfoNetworkPage extends StatefulWidget {
  const InfoNetworkPage({super.key});

  @override
  State<InfoNetworkPage> createState() => _InfoNetworkPageState();
}

class _InfoNetworkPageState extends State<InfoNetworkPage> {
  final NetworkService _service = NetworkService();

  String connectionType = "—";
  String localIP = "—";
  String publicIP = "—";
  String ssid = "—";
  String bssid = "—";
  String gateway = "—";
  String broadcast = "—";
  String interfaceName = "-";

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    await _service.debugInterfaces();

    final type = await _service.getConnectionType();
    final ipLocal = await _service.getLocalIP();
    final ipPublic = await _service.getPublicIP();
    final wifiSSID = await _service.getSSID();
    final wifiBSSID = await _service.getBSSID();
    final wifiGateway = await _service.getSmartGateway();
    final wifiBroadcast = await _service.getSmartBroadcast();
    final ifaceName = await _service.getActiveInterfaceName();


    setState(() {
      connectionType = type ?? "—";
      localIP = ipLocal ?? "—";
      publicIP = ipPublic ?? "—";
      ssid = wifiSSID ?? "—";
      bssid = wifiBSSID ?? "—";
      gateway = wifiGateway ?? "—";
      broadcast = wifiBroadcast ?? "—";
      interfaceName = ifaceName ?? "—";

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Info rete"),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _loadNetworkInfo,
        child: Icon(Icons.refresh),
      ),
      
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sempre visibili
          NetworkInfoTile(
            icon: Icons.wifi,
            title: "Tipo connessione",
            value: connectionType,
          ),
          NetworkInfoTile(
            icon: Icons.router,
            title: "IP locale",
            value: localIP,
          ),
          NetworkInfoTile(
            icon: Icons.public,
            title: "IP pubblico",
            value: publicIP,
          ),
          NetworkInfoTile(
            icon: Icons.device_hub,
            title: "Interfaccia attiva",
            value: interfaceName,
          ),
          NetworkInfoTile(
            icon: Icons.dns,
            title: "Gateway",
            value: gateway,
          ),
          NetworkInfoTile(
            icon: Icons.broadcast_on_home,
            title: "Broadcast",
            value: broadcast,
          ),

          // Solo se Wi‑Fi
          if (connectionType == "Wi‑Fi") ...[
            NetworkInfoTile(
              icon: Icons.wifi_tethering,
              title: "SSID",
              value: ssid,
            ),
            NetworkInfoTile(
              icon: Icons.qr_code_2,
              title: "BSSID",
              value: bssid,
            ),

          ],
        ],
      ),
    );
  }
}

class NetworkInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const NetworkInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
