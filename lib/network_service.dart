import 'dart:convert';

//import 'package:carrier_info/carrier_info.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();



  bool isHotspotIP(String ip) {
    return ip.startsWith("192.168.43.") ||  // android
        ip.startsWith("192.168.137.") ||   //windows
        ip.startsWith("172.20.10.");      //apple
  }


  // Tipo di connession versione avanzata
  Future<String> getConnectionType() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false, //non includere l'interfaccia di loopback, perchè lo non  rappresenta una connessione reale
      type: InternetAddressType.IPv4,  //mostra solo interfaccie con indirizzo Ipv4, e il plugin netwotk_info_plus usa IPv4
    );

    if (interfaces.isEmpty) {
      return "Nessuna connessione";
    }

    for (var iface in interfaces) {
      final name = iface.name.toLowerCase();

      //otteniamo l'ip per capire se è hotspot
      for(var addr  in iface.addresses){
        final ip = addr.address;
        if(isHotspotIP(ip)){
          return "Hotspot";
        }
      }

      // Ethernet reale o virtuale
      if (name.contains("ethernet") || name.contains("eth") || name.contains("lan")) {
        return "Ethernet";
      }

      // Wi‑Fi reale o hotspot Wi‑Fi
      if (name.contains("wi") || name.contains("wlan") || name.contains("wifi")) {
        return "Wi‑Fi";
      }

      // Hotspot USB (viene visto come Ethernet virtuale)
      if (name.contains("rndis") || name.contains("usb")) {
        return "Ethernet (USB Hotspot)";
      }

      // VPN
      if (name.contains("vpn") || name.contains("tun") || name.contains("tap")) {
        return "VPN";
      }
    }
    return "Sconosciuta";
  }

  Future<String?> getLocalIP() async {
    final type = await getConnectionType();

    if (type == "Wi‑Fi") {
      return await _networkInfo.getWifiIP();  //questo funziona solo per wifi
    } else {
      return await getGenericLocalIP();
    }
  }

  Future<String?> getGenericLocalIP() async {  //aggiunto dopo perchè serve per ethernet
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


  // qua distinguiamo se siamo in wifi o no, infatti se siamo in wifi utiizziamo i plugin(quindi valori reali)
  Future<String?> getSmartGateway() async {
    final type = await getConnectionType();
    final ip = await getLocalIP();
    if (ip == null) return null;

    if (type == "Wi‑Fi") {
      return await _networkInfo.getWifiGatewayIP();
    } else {
      return await getEthernetGateway(ip);
    }
  }


  Future<String?> getSmartBroadcast() async {
    final type = await getConnectionType();
    final ip = await getLocalIP();
    if (ip == null) return null;

    if (type == "Wi‑Fi") {
      return await _networkInfo.getWifiBroadcast();
    } else {
      return await getEthernetBroadcast(ip);
    }
  }

  // Solo WiFi
  Future<String?> getSSID() async => await _networkInfo.getWifiName();

  Future<String?> getBSSID() async => await _networkInfo.getWifiBSSID();

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

  Future<void> debugInterfaces() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    print("=== INTERFACCE DI RETE ATTIVE ===");

    for (var iface in interfaces) {
      print("Interfaccia: ${iface.name}");
      for (var addr in iface.addresses) {
        print("  IP: ${addr.address}");
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