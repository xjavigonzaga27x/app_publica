import 'package:flutter/material.dart';
import 'package:app_p_publica/screens/hermanos_screen.dart';
import 'package:app_p_publica/screens/territorios_screen.dart';
import 'package:app_p_publica/screens/horarios_screen.dart';
import 'package:app_p_publica/screens/reportes_screen.dart';
import 'package:app_p_publica/screens/pdf_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas a mostrar
  static final List<Widget> _screens = <Widget>[
    const HermanosScreen(),
    const TerritoriosScreen(),
    const HorariosScreen(),
    const ReportesScreen(),
    const PdfScreen(),
  ];

  // Lista de colores para cada pantalla
  static final List<Color> _screenColors = [
    Colors.blue, // Hermanos
    Colors.green, // Territorios
    Colors.orange, // Horarios
    Colors.purple, // Reportes
    Colors.teal, // PDF
  ];

  // Lista de títulos para la AppBar
  static final List<String> _titles = <String>[
    'Hermanos',
    'Territorios',
    'Horarios',
    'Reportes',
    'PDF',
  ];

  // Lista de íconos para la barra de navegación
  static final List<IconData> _iconosNav = [
    Icons.people,
    Icons.map,
    Icons.schedule,
    Icons.summarize,
    Icons.picture_as_pdf,
  ];

  // Cambiar la pantalla seleccionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Color de la pantalla actual
    final currentColor = _screenColors[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_iconosNav[_selectedIndex], color: Colors.white),
            const SizedBox(width: 10),
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: currentColor,
        elevation: 0,
        actions: [
          // Mostrar icono de ayuda
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _mostrarAyuda(context),
          ),
        ],
      ),
      // Mostrar la pantalla seleccionada
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [currentColor.withOpacity(0.05), Colors.transparent],
          ),
        ),
        child: _screens.elementAt(_selectedIndex),
      ),
      // Navegación inferior
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: List.generate(
              _titles.length,
              (index) => BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _selectedIndex == index
                            ? _screenColors[index].withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_iconosNav[index]),
                ),
                label: _titles[index],
                backgroundColor: Colors.white,
              ),
            ),
            currentIndex: _selectedIndex,
            selectedItemColor: currentColor,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            elevation: 0,
          ),
        ),
      ),
    );
  }

  // Mostrar diálogo de ayuda
  void _mostrarAyuda(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.help, color: _screenColors[_selectedIndex]),
                const SizedBox(width: 10),
                const Text('Ayuda'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _seccionAyuda(
                    'Hermanos',
                    'Registre a los hermanos que participan en la predicación pública y marque si están activos o no.',
                    Icons.people,
                    Colors.blue,
                  ),
                  const Divider(),
                  _seccionAyuda(
                    'Territorios',
                    'Cree los territorios donde se realiza la predicación. Puede añadir una descripción para facilitar su identificación.',
                    Icons.map,
                    Colors.green,
                  ),
                  const Divider(),
                  _seccionAyuda(
                    'Horarios',
                    'Asigne hermanos a territorios específicos en días y horarios determinados.',
                    Icons.schedule,
                    Colors.orange,
                  ),
                  const Divider(),
                  _seccionAyuda(
                    'Reportes',
                    'Visualice los horarios organizados por territorio para facilitar la coordinación.',
                    Icons.summarize,
                    Colors.purple,
                  ),
                  const Divider(),
                  _seccionAyuda(
                    'PDF',
                    'Genere informes en formato PDF de los horarios por territorio para imprimir o compartir.',
                    Icons.picture_as_pdf,
                    Colors.teal,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: _screenColors[_selectedIndex],
                ),
                child: const Text('Entendido'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
    );
  }

  // Widget para cada sección de ayuda
  Widget _seccionAyuda(
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(descripcion, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
