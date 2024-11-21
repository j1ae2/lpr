import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peerdart/peerdart.dart';

import 'bus.dart';
import 'constants.dart';

class DataConnectionExample extends StatefulWidget {
  const DataConnectionExample({Key? key}) : super(key: key);

  @override
  State<DataConnectionExample> createState() => _DataConnectionExampleState();
}

class _DataConnectionExampleState extends State<DataConnectionExample> {
  Bus? _selectedBus;
  List<Bus> _buses = [];

  Peer peer = Peer(
      id: "ac8a4d66-3d0d-4e96-8d68-b407537d31b7",
      options: PeerOptions(debug: LogLevel.All));
  late DataConnection conn;
  bool connected = false;
  bool error = false;

  @override
  void dispose() {
    peer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getRutas();

    peer.on<DataConnection>("connection").listen((event) {
      conn = event;
      setState(() {
        connected = true;
      });

      conn.on("data").listen((data) async {
        try {
          double saldo = await realizarPago(data);
          conn.send(saldo);
        } catch (e) {
          conn.send(-1);
          setState(() {
            error = true;
          });
          closeConnection();
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              error = false;
            });
          });
        }
      });

      conn.on("close").listen((event) {
        setState(() {
          connected = false;
        });
      });
    });
  }

  void sendHelloWorld() {
    conn.send("Hello world!");
  }

  void closeConnection() {
    setState(() {
      connected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0XFF405f90),
          title: const Text(
            'Torniquete virtual',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              DropdownButton<Bus>(
                hint: const Text('Seleccione una ruta'),
                value: _selectedBus,
                onChanged: (Bus? newValue) {
                  setState(() {
                    _selectedBus = newValue;
                  });
                },
                items: _buses.map<DropdownMenuItem<Bus>>((Bus ruta) {
                  return DropdownMenuItem<Bus>(
                    value: ruta,
                    child: Text(ruta.nombre),
                  );
                }).toList(),
              ),
              _renderState(),
            ],
          ),
        ));
  }

  Widget _renderState() {
    Color bgColor = connected
        ? Colors.green
        : error
            ? Colors.red
            : Colors.grey;
    Color txtColor = Colors.white;
    String txt = connected
        ? "Realizando pago..."
        : error
            ? "Saldo insuficiente"
            : "Acerque su tarjeta";
    return Container(
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        txt,
        style:
            Theme.of(context).textTheme.titleLarge?.copyWith(color: txtColor),
      ),
    );
  }

  void getRutas() async {
    var url = "$BACKEND_URL/elimapass/v1/buses/";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      List<Bus> buses = Bus.listFromJson(json);
      setState(() {
        _buses = buses;
      });
    }
    return;
  }

  Future<double> realizarPago(String tarjetaId) async {
    var url = "$BACKEND_URL/elimapass/v1/pagar_viaje/";

    var body = {"tarjetaId": tarjetaId, "busId": _selectedBus!.id};

    final response = await http.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body));

    print(response.statusCode);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final saldo = json["saldo_actual"];
      return saldo;
    } else {
      throw Exception('Ha ocurrido un error desconocido. Inténtelo más tarde');
    }
  }
}
