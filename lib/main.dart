import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'detail_screen.dart';
import 'manual_rut_input_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta RUT',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    _inputController.addListener(() {
      final input = _inputController.text.trim();
      if (input.isNotEmpty && _isValidRut(input)) {
        _processInput(input);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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
    final RegExp regex = RegExp(r'^(\d{1,8})-([0-9kK])$');
    final match = regex.firstMatch(rut);

    if (match == null) return false;

    final String rutBody = match.group(1)!;
    final String dv = match.group(2)!.toUpperCase();

    return _calculateDV(rutBody) == dv;
  }

  String _formatRut(String rut) {
    final RegExp regex = RegExp(r'^(\d+)-([0-9kK])$');
    final match = regex.firstMatch(rut);

    if (match == null) return rut;

    String rutBody = match.group(1)!;
    String dv = match.group(2)!;

    final buffer = StringBuffer();
    for (int i = 0; i < rutBody.length; i++) {
      if (i > 0 && (rutBody.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(rutBody[i]);
    }

    return '${buffer.toString()}-$dv';
  }

  void _processInput(String input) {
    final String rut = input.trim();

    if (rut.isEmpty) return;

    final formattedRut = _formatRut(rut);
    _inputController.text = formattedRut;

    if (!_isValidRut(rut)) {
      _mostrarDialogo('Error', 'El RUT escaneado no es válido.');
      return;
    }

    _clearInput();

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          nombreCliente: 'Cliente válido',
          estado: 'Activo',
        ),
      ),
    );
  }

  void _clearInput() {
    _inputController.clear();
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

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(onScanCompleted: (qrData) {
          final extractedRut = _extractRunFromQR(qrData);
          if (extractedRut != null) {
            _inputController.text = _formatRut(extractedRut);
          } else {
            _mostrarDialogo('Error', 'No se pudo encontrar un RUN en el código QR.');
          }
        }),
      ),
    );
  }

  String? _extractRunFromQR(String qrData) {
    final match = RegExp(r'RUN=(\d{1,8}-[0-9kK])').firstMatch(qrData);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Consulta de RUT',
          style: TextStyle(
            color: Colors.white,
            fontSize: screenHeight * 0.03,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event.character != null) {
            _inputController.text += event.character!;
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    labelText: 'RUT escaneado',
                    border: OutlineInputBorder(),
                    enabled: true,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualRutInputScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  minimumSize: Size(double.infinity, buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Ingresar RUT manualmente',
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
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  final void Function(String qrData) onScanCompleted;

  QRScannerScreen({required this.onScanCompleted});

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan(BuildContext context, String qrData) {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    widget.onScanCompleted(qrData);

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.5;

    return Scaffold(
      appBar: AppBar(
        title: Text('Escanear QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isScanning) {
                  _handleScan(context, barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 5,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 5,
                      height: 30,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 5,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 5,
                      height: 30,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 30,
                      height: 5,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 5,
                      height: 30,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 5,
                      color: Colors.red,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 5,
                      height: 30,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Coloca el QR dentro del recuadro para escanear',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.height * 0.02,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}