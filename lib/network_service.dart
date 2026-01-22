import 'dart:convert';

//import 'package:carrier_info/carrier_info.dart';
//import 'package:carrier_info/carrier_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_signal_strength/flutter_signal_strength.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:sim_card_info/sim_card_info.dart';
import 'package:sim_card_info/sim_info.dart';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();

  /*bool isHotspotIP(String ip) {
    return ip.startsWith("192.168.43.") ||  // android
        ip.startsWith("192.168.137.") ||   //windows
        ip.startsWith("172.20.10.");      //apple
  }*/

  Future<String> getConnectionType() async {
    // 1. Prima controlliamo il tipo di rete a livello di interfaccia
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity == ConnectivityResult.none) {
      return "Nessuna connessione";
    }

    if (connectivity == ConnectivityResult.mobile) {
      return "Mobile";
    }

    // 2. Se siamo qui, siamo in Wi‑Fi, Ethernet o VPN
    final interfaces = await NetworkInterface.list(
      includeLoopback: false, //interfaccia di rete virtuale interna al sistema operativo(ha sempre lo stesso indirizzo), non è una connessione reale. Se fosse true, verrebbe sempre trovata una connessione anche quando non c'è
      type: InternetAddressType.IPv4, //mostra solo interfaccie con indirizzo Ipv4, e il plugin netwotk_info_plus usa IPv4
    );

    if (interfaces.isEmpty) return "Nessuna connessione";

    for (var iface in interfaces) {
      // Ignora interfacce senza IP
      if (iface.addresses.isEmpty) continue;

      final name = iface.name.toLowerCase();

      // 3. Riconoscimento hotspot tramite IP
      /*for (var addr in iface.addresses) {
        final ip = addr.address;
        if (isHotspotIP(ip)) {
          return "Hotspot";
        }
      }*/

      // 4. Riconoscimento Wi‑Fi reale
      if (name.contains("wlan") || name.contains("wifi")) {
        return "Wi-Fi";
      }

      // 5. Ethernet reale
      if (name.contains("eth") || name.contains("lan")) {
        return "Ethernet";
      }

      // 6. USB tethering
      if (name.contains("rndis") || name.contains("usb")) {
        return "Ethernet (USB Hotspot)";
      }

      // 7. VPN
      if (name.contains("vpn") || name.contains("tun") || name.contains("tap")) {
        return "VPN";
      }
    }

    return "Sconosciuta";
  }



  Future<String?> getLocalIP() async {
    final type = await getConnectionType();

    if (type == "Wi-Fi") {
      return await _networkInfo.getWifiIP();  //questo funziona solo per wifi
    } else {
      return await getGenericLocalIP();
    }
  }

  Future<String?> getGenericLocalIP() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        return addr.address;
      }
    }
    return null;
  }

  // ip per mobile
  Future<String?> getLocalIPv6() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv6,
      );

      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          final ip = addr.address;

          // Escludiamo IPv6 link-local (fe80::)
          if (!ip.startsWith("fe80")) {
            return ip;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  //Ip Pubblico
  Future<String?> getPublicIP() async {
    try {
      final response = await http.get(Uri.parse("https://api.ipify.org?format=json")); // servizio pubblico che restituisce il mio IP
      return jsonDecode(response.body)["ip"];
    } catch (e) {
      return null;
    }
  }

  // calcoliamo gateway e broadcast perchè quasi tutte le reti domestiche usano subnet/24, quindi gateway.1 e broadcast.255
  // sooìno generali(valori virtuali) e funzionano solo per ethernet, hotspot
  Future<String?> getEthernetGateway(String ip) async {
    final parts = ip.split(".");
    if (parts.length != 4) return null;

    return "${parts[0]}.${parts[1]}.${parts[2]}.1";
  }

  Future<String?> getEthernetBroadcast(String ip) async {
    final parts = ip.split(".");
    if (parts.length != 4) return null;

    return "${parts[0]}.${parts[1]}.${parts[2]}.255";
  }

  //////////////////////////////////////////////////////////////////////
  // qua distinguiamo se siamo in wifi o no, infatti se siamo in wifi utiizziamo i plugin(quindi valori reali)
  ///////////////////////WIFI////////////////////////////////////////////
  Future<String?> getGateway() async {
    final type = await getConnectionType();
    final ip = await getLocalIP();
    if (ip == null) return null;

    if (type == "Wi-Fi") {
      return await _networkInfo.getWifiGatewayIP();
    } else {
      return await getEthernetGateway(ip);
    }
  }


  Future<String?> getBroadcast() async {
    final type = await getConnectionType();
    final ip = await getLocalIP();
    if (ip == null) return null;

    if (type == "Wi-Fi") {
      return await _networkInfo.getWifiBroadcast();
    } else {
      return await getEthernetBroadcast(ip);
    }
  }

  Future<String?> getSubnetMask() async {
    final type = await getConnectionType();

    if(type == "Wi-Fi"){
      return await _networkInfo.getWifiSubmask();
    }

    final ip = await getLocalIP();
    if(ip == null) return null;

    return "255.255.255.0"; // standard per hotspot e reti domestiche
  }


  // SSID e BSSID richiedono permessi di geolocalizzazione
  Future<bool> _locationPermission() async {
    //controllo il permesso
    var status = await Permission.location.status;

    if(!status.isGranted){
      status = await Permission.location.request();
      if(!status.isGranted){
        return false;
      }
    }

    //controllo se il GPS è attivo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if(!serviceEnabled) {
      return false;
    }

    return true;
  }

  // Solo WiFi
  Future<String?> getSSID() async{
    final enabled = await _locationPermission();
    if(!enabled) return null;

    return await _networkInfo.getWifiName();
  }

  Future<String?> getBSSID() async {
    final enabled = await _locationPermission();
    if(!enabled) return null;

    return await _networkInfo.getWifiBSSID();
  }

  //Future<String?> getGateway() async => await _networkInfo.getWifiGatewayIP();

  //Future<String?> getBroadcast() async => await _networkInfo.getWifiBroadcast();


  Future<String?> getActiveInterfaceName() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    if (interfaces.isEmpty) return null;

    // Prendiamo la prima interfaccia attiva
    return interfaces.first.name;
  }

  //potenza del segnale WiFi
  Future<int?> getWiFiSignal() async {
    try{
      return await FlutterSignalStrength().getWifiSignalStrength();
    } catch (_){
      return null;
    }
  }

  Future<int?> getWifiSignaDbm() async {
    try{
      return await FlutterSignalStrength().getWifiSignalStrengthDbm();
    } catch (_){
      return null;
    }
  }

  ///////////////////////////////////////////////////////////////
  /////////////////MOBILE//////////////////////////////////////

  Future<String?> getCarrierName() async {
    try{
      final info = await SimCardInfo().getSimInfo();
      print("SIM INFO: $info");
      if(info == null || info.isEmpty) return null;

      final sim = info.first;
      return sim.carrierName;
    } catch (_){
      return null;
    }
  }


  //potenza del segnale Mobile
  Future<int?> getMobileSignal() async {
    try{
      return await FlutterSignalStrength().getCellularSignalStrength();
    } catch (_){
      return null;
    }
  }

  Future<int?> getMobileSignalDbm() async {
    try{
      return await FlutterSignalStrength().getCellularSignalStrengthDbm();
    } catch (_){
      return null;
    }
  }

  String signalQualityText(int? level) {
    const labels = [
      "Nessun segnale",
      "Scarsa",
      "Buona",
      "Ottima",
      "Eccellente",
    ];

    if (level == null) return "Sconosciuta";
    return labels[level.clamp(0, 4)];
  }


  //////////////////////////////////////////////////////////////////////////////////////////
  Future<void> debugInterfaces() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    print("=== INTERFACCE DI RETE ATTIVE ===");

    for (var iface in interfaces) {
      print("Interfaccia: ${iface.name}");
      for (var addr in iface.addresses) {
        print("IP: ${addr.address}");
      }
    }

    print("=================================");
  }

}

//Tipo di Connessione
/*Future<String?> getConnectionTypeOne() async {
    final result = await Connectivity().checkConnectivity();

    switch (result) {
      case ConnectivityResult.wifi:
        return "Wi‑Fi";
      case ConnectivityResult.mobile:
        return "Mobile";
      case ConnectivityResult.ethernet:
        return "Ethernet";
      case ConnectivityResult.none:
        return "Nessuna connessione";
      default:
        return "Sconosciuta";
    }
  }*/
