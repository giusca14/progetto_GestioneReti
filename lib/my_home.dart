import 'package:flutter/material.dart';
import 'package:network_info_demo/info_network.dart';


class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InfoNetworkPage()),
            );
          },
          child: const Text("Vai alla seconda schermata"),
        ),
      ),
    );
  }
}
