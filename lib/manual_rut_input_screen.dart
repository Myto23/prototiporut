import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detail_screen.dart';

class ManualRutInputScreen extends StatefulWidget {
  @override
  _ManualRutInputScreenState createState() => _ManualRutInputScreenState();
}

class _ManualRutInputScreenState extends State<ManualRutInputScreen> {
  final TextEditingController _rutController = TextEditingController();
  bool _isButtonEnabled = false;

  String _calculateDV(String rutBody) {
    List<int> series = [2, 3, 4, 5, 6, 7];
    int sum = 0;

    for (int i = 0; i < rutBody.length; i++) {
      sum += int.parse(rutBody[rutBody.length - 1 - i]) * series[i % series.length];
    }

    int remainder = sum % 11;
    int dv = 11 - remainder;

    if (dv == 11) return '0';
    if (dv == 10) return 'K';
    return dv.toString();
  }

  bool _isValidRut(String rut) {
    final RegExp regex = RegExp(r'^(\d{7,8})-([0-9kK])$');
    final match = regex.firstMatch(rut);

    if (match == null) return false;

    final String rutBody = match.group(1)!;
    final String dv = match.group(2)!.toUpperCase();

    return _calculateDV(rutBody) == dv;
  }

  void _consultarRut() {
    final String rut = _rutController.text;

    if (rut == '11111111-1') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(
            nombreCliente: 'Cliente Válido',
            estado: 'Activo',
          ),
        ),
      );
      return;
    }

    if (rut == '22222222-2') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(
            nombreCliente: 'Cliente Inactivo',
            estado: 'Inactivo',
          ),
        ),
      );
      return;
    }

    if (rut == '33333333-3') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(
            nombreCliente: 'Titular Inactivo',
            estado: 'Inactivo',
          ),
        ),
      );
      return;
    }

    _mostrarDialogo('Cliente no encontrado', 'El cliente no existe en la base de datos.');
  }

  void _mostrarDialogo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.blue,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: 16.0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Consulta de RUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _rutController,
                    inputFormatters: [RutInputFormatter()],
                    decoration: InputDecoration(
                      labelText: 'Ingrese el RUT',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (text) {
                      setState(() {
                        _isButtonEnabled = _isValidRut(text);
                      });
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? _consultarRut : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: Size(double.infinity, screenHeight * 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: Text(
                      'Consultar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenHeight * 0.02,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RutInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll('-', '');
    if (text.length > 7) {
      text = text.substring(0, text.length - 1) +
          '-' +
          text.substring(text.length - 1);
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
