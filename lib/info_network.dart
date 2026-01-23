import 'package:flutter/material.dart';
import 'network_service.dart';

class InfoNetworkPage extends StatefulWidget {
  const InfoNetworkPage({super.key});

  @override
  State<InfoNetworkPage> createState() => _InfoNetworkPageState();
}

class _InfoNetworkPageState extends State<InfoNetworkPage> {
  final NetworkService _service = NetworkService();

  String connectionType = "-";
  String connectionStatus = "-";
  String localIP = "-";
  String publicIP = "-";
  String ssid = "-";
  String bssid = "-";
  String gateway = "-";
  String broadcast = "-";
  String subnetMask = "-";
  String ipv6 = "-";
  String carrierName = "-";
  String mSignal = "-";
  String wSignal = "-";
  String mSignalDbm = "-";
  String wSignalDbm= "-";
  String mSignalQuality = "-";
  String wSignalQuality = "-";
  String interfaceName = "-";

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    await _service.debugInterfaces();

    final type = await _service.getConnectionType();
    final isConnected = type != "Nessuna connessione";
    final statusText = isConnected ? "Connesso" : "Nessuna connessione";
    final ipLocal = await _service.getLocalIP();
    final ipPublic = await _service.getPublicIP();
    final wifiSSID = await _service.getSSID();
    final wifiBSSID = await _service.getBSSID();
    final wifiGateway = await _service.getGateway();
    final wifiBroadcast = await _service.getBroadcast();
    final wifiSubnetMask = await _service.getSubnetMask();
    final mobileIpv6 = await _service.getLocalIPv6();
    final mobileCarrierName = await _service.getCarrierName();
    final mobileSignal = await _service.getMobileSignal();
    final wifiSignal = await _service.getWiFiSignal();
    final mobileSignalDbm = await _service.getMobileSignalDbm();
    final wifiSignalDbm = await _service.getWifiSignaDbm();
    final mobileSignalQuality = await _service.signalQualityText(mobileSignal);
    final wifiSignalQuality = await _service.signalQualityText(wifiSignal);
    final iFaceName = await _service.getActiveInterfaceName();

    String verifiedType = type ?? "-";

    // ho ggiunto questo per riconoscere in modo più affidabile mobile, dato che checkConnectivity non è robusto
    if(iFaceName != null &&(
        iFaceName.contains("rmnet") ||
        iFaceName.contains("ccmni") ||
        iFaceName.contains("pdp")
    )){
      verifiedType = "Mobile";
    }

    setState(() {
      connectionType = verifiedType;
      connectionStatus = statusText;
      localIP = ipLocal ?? "-";
      publicIP = ipPublic ?? "-";
      ssid = wifiSSID ?? "-";
      bssid = wifiBSSID ?? "-";
      gateway = wifiGateway ?? "-";
      broadcast = wifiBroadcast ?? "-";
      subnetMask = wifiSubnetMask ?? "-";
      ipv6 = mobileIpv6 ?? "-";
      carrierName = mobileCarrierName ?? "-";
      mSignal = mobileSignal?.toString() ?? "-";
      wSignal = wifiSignal?.toString() ?? "-";
      mSignalDbm = mobileSignalDbm.toString();
      wSignalDbm = wifiSignalDbm.toString();
      mSignalQuality = mobileSignalQuality;
      wSignalQuality = wifiSignalQuality;
      interfaceName = iFaceName ?? "-";

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
            icon: Icons.info_outline,
            title: "Stato connessione",
            value: connectionStatus,
          ),
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
            icon: Icons.login,
            title: "Gateway",
            value: gateway,
          ),
          NetworkInfoTile(
            icon: Icons.broadcast_on_home,
            title: "Broadcast",
            value: broadcast,
          ),

          // Solo se Wi‑Fi
          if (connectionType == "Wi-Fi") ...[
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
            NetworkInfoTile(
              icon: Icons.account_tree,
              title: "SubnetMask",
              value: subnetMask,
            ),
            NetworkInfoTile(
              icon: Icons.signal_cellular_alt,
              title: "Intensità segnale",
              value: "$wSignal/4 ---------> $wSignalDbm dbm ($wSignalQuality) ",
            ),
          ],
          if(connectionType == "Mobile")...[
            NetworkInfoTile(
              icon: Icons.sim_card,
              title: "Operatore",
              value: carrierName,
            ),
            NetworkInfoTile(
              icon: Icons.signal_cellular_alt,
              title: "Intensità di segnale",
              value: "$mSignal/4 ---------> $mSignalDbm dbm ($mSignalQuality) ",
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
