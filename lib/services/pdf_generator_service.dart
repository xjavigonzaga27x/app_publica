import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/models/hermano.dart';
import 'package:app_p_publica/services/firebase_service.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PdfGeneratorService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<File> generateAllHorariosPdf() async {
    // Crear documento PDF
    final pdf = pw.Document();

    // Definir estilos
    final titleStyle = pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blue900,
    );

    final normalStyle = pw.TextStyle(fontSize: 10, color: PdfColors.black);

    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );

    // Definir días de la semana en orden
    final diasSemana = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    // Definir intervalos fijos de horas (de hora en hora)
    final List<String> intervalosFijos = [
      '06:00 - 07:00',
      '07:00 - 08:00',
      '08:00 - 09:00',
      '09:00 - 10:00',
      '10:00 - 11:00',
      '11:00 - 12:00',
      '15:00 - 16:00',
      '16:00 - 17:00',
      '17:00 - 18:00',
    ];

    // Función para determinar en qué intervalos fijos cae un horario
    List<String> obtenerIntervalosFijosParaHorario(
      int inicioMinutos,
      int finMinutos,
    ) {
      List<String> intervalos = [];

      // Convertir minutos a horas (como enteros)
      int horaInicio = inicioMinutos ~/ 60;
      int horaFin = finMinutos ~/ 60;
      int minFin = finMinutos % 60;

      // Si termina exactamente en el minuto 0 de una hora, restamos 1 a la hora final
      // Por ejemplo, 07:00 - 08:00 solo debe estar en el intervalo 07:00 - 08:00, no en 08:00 - 09:00
      if (minFin == 0 && horaFin > horaInicio) {
        horaFin--;
      }

      // Asignar a cada intervalo fijo que corresponda
      for (int hora = horaInicio; hora <= horaFin; hora++) {
        String intervaloFijo =
            '${hora.toString().padLeft(2, '0')}:00 - ${(hora + 1).toString().padLeft(2, '0')}:00';

        // Verificar si este intervalo fijo está en nuestra lista
        if (intervalosFijos.contains(intervaloFijo)) {
          intervalos.add(intervaloFijo);
        }
      }

      return intervalos;
    }

    // Función para formatear la fecha actual
    String currentDate() {
      final now = DateTime.now();
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(now);
    }

    // Cargar todos los territorios
    final territorios = await _firebaseService.getTerritorios();

    // Cargar todos los hermanos para tener un mapa por ID
    final hermanos = await _firebaseService.getHermanos();
    Map<String, Hermano> hermanosMap = {};
    for (var hermano in hermanos) {
      hermanosMap[hermano.id] = hermano;
    }
    print('Hermanos cargados: ${hermanos.length}');

    // Procesar todos los territorios
    List<Map<String, dynamic>> territoriosData = [];

    for (var territorio in territorios) {
      print(
        'Procesando territorio: ${territorio.nombre} (ID: ${territorio.id})',
      );

      // Obtener horarios directamente de Firestore
      final horariosSnapshot =
          await _firestore
              .collection('horarios')
              .where('territorioId', isEqualTo: territorio.id)
              .get();

      print(
        'Horarios encontrados para ${territorio.nombre}: ${horariosSnapshot.docs.length}',
      );

      if (horariosSnapshot.docs.isEmpty) {
        // Sin horarios, agregar territorio sin datos
        territoriosData.add({'territorio': territorio, 'hayHorarios': false});
        continue;
      }

      // Inicializar estructura para los intervalos fijos
      Map<String, Map<String, List<String>>> horariosPorIntervaloFijo = {};

      // Inicializar la estructura para cada intervalo fijo
      for (var intervalo in intervalosFijos) {
        horariosPorIntervaloFijo[intervalo] = {};
        for (var dia in diasSemana) {
          horariosPorIntervaloFijo[intervalo]![dia] = [];
        }
      }

      // Lista de intervalos fijos que tienen algún hermano asignado
      Set<String> intervalosFijosUsados = {};

      // Procesar cada horario y asignarlo a los intervalos fijos correspondientes
      for (var doc in horariosSnapshot.docs) {
        final data = doc.data();
        final hermanoId = data['hermanoId'] as String;
        final dia = data['dia'] as String;
        final inicioMinutos = data['horaInicioMinutos'] as int;
        final finMinutos = data['horaFinMinutos'] as int;

        // Verificar si el hermano existe y está activo
        final hermano = hermanosMap[hermanoId];
        if (hermano == null || !hermano.activo) {
          // Omitir hermanos que no existan o estén inactivos
          print('Omitiendo hermano inactivo o no encontrado: $hermanoId');
          continue;
        }

        // Obtener nombre completo del hermano (con identificador si existe)
        String nombreHermano = hermano.nombreCompleto;

        // Determinar en qué intervalos fijos cae este horario
        List<String> intervalosCorrespondientes =
            obtenerIntervalosFijosParaHorario(inicioMinutos, finMinutos);

        print(
          'Horario: $nombreHermano, $dia, ${inicioMinutos ~/ 60}:${(inicioMinutos % 60).toString().padLeft(2, '0')} - ${finMinutos ~/ 60}:${(finMinutos % 60).toString().padLeft(2, '0')}',
        );
        print('  Asignado a intervalos: $intervalosCorrespondientes');

        // Asignar el hermano a cada intervalo correspondiente
        for (var intervalo in intervalosCorrespondientes) {
          horariosPorIntervaloFijo[intervalo]![dia]!.add(nombreHermano);
          intervalosFijosUsados.add(intervalo);
        }
      }

      // Convertir a lista y ordenar
      final List<String> intervalosFijosOrdenados =
          intervalosFijosUsados.toList();
      intervalosFijosOrdenados.sort((a, b) {
        final horaInicioA = int.parse(a.split(':')[0]);
        final horaInicioB = int.parse(b.split(':')[0]);
        return horaInicioA.compareTo(horaInicioB);
      });

      // Verificar si hay horarios con hermanos activos
      bool hayHorariosActivos = intervalosFijosUsados.isNotEmpty;

      territoriosData.add({
        'territorio': territorio,
        'hayHorarios': hayHorariosActivos,
        'horariosPorIntervaloFijo': horariosPorIntervaloFijo,
        'intervalosFijosOrdenados': intervalosFijosOrdenados,
      });
    }

    // Generar PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Orientación horizontal
        margin: const pw.EdgeInsets.all(25),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Horarios de Predicación', style: titleStyle),
                  pw.Text('Fecha: ${currentDate()}', style: normalStyle),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Divider(),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generado por: App de Predicación',
                    style: normalStyle,
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: normalStyle,
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          final List<pw.Widget> widgets = [];

          // Construir secciones para cada territorio
          for (var territorioData in territoriosData) {
            final territorio = territorioData['territorio'] as Territorio;
            final hayHorarios = territorioData['hayHorarios'] as bool;

            // Agregar título del territorio
            widgets.add(
              pw.Header(
                level: 1,
                child: pw.Text(territorio.nombre, style: titleStyle),
              ),
            );

            // Agregar descripción si existe
            if (territorio.descripcion.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 5),
                  child: pw.Text(territorio.descripcion, style: normalStyle),
                ),
              );
            }

            if (!hayHorarios) {
              // Mensaje si no hay horarios
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Text(
                    'No hay horarios registrados para este territorio.',
                    style: normalStyle,
                  ),
                ),
              );
            } else {
              // Datos para construir la tabla
              final horariosPorIntervaloFijo =
                  territorioData['horariosPorIntervaloFijo']
                      as Map<String, Map<String, List<String>>>;
              final intervalosFijosOrdenados =
                  territorioData['intervalosFijosOrdenados'] as List<String>;

              // Crear tabla con intervalos fijos
              widgets.add(
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 0.5,
                  ),
                  tableWidth: pw.TableWidth.max,
                  columnWidths: {
                    0: const pw.FixedColumnWidth(75), // Intervalo
                  },
                  children: [
                    // Cabecera de la tabla
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue700),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Intervalo',
                            style: headerStyle,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        ...diasSemana
                            .map(
                              (dia) => pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  dia,
                                  style: headerStyle,
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),

                    // Filas de intervalos fijos
                    ...intervalosFijosOrdenados.map((intervalo) {
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          // Columna de intervalo
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(intervalo, style: normalStyle),
                          ),
                          // Columnas de días
                          ...diasSemana.map((dia) {
                            final hermanos =
                                horariosPorIntervaloFijo[intervalo]?[dia] ?? [];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children:
                                    hermanos.isEmpty
                                        ? [
                                          pw.Text(
                                            '-',
                                            style: normalStyle,
                                            textAlign: pw.TextAlign.center,
                                          ),
                                        ]
                                        : hermanos
                                            .map(
                                              (hermano) => pw.Text(
                                                hermano,
                                                style: normalStyle,
                                              ),
                                            )
                                            .toList(),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              );
            }

            // Espacio entre territorios
            widgets.add(pw.SizedBox(height: 20));
          }

          return widgets;
        },
      ),
    );

    // Guardar el archivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/horarios_predicacion.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<void> generateAndOpenAllHorariosPdf() async {
    try {
      // Generar PDF con todos los territorios
      final file = await generateAllHorariosPdf();

      // Abrir el archivo
      await OpenFile.open(file.path);
    } catch (e) {
      print('Error al generar PDF: $e');
      rethrow;
    }
  }

  Future<void> shareAllHorariosPdf() async {
    try {
      // Generar PDF con todos los territorios
      final file = await generateAllHorariosPdf();

      // Compartir el archivo
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Horarios de predicación');
    } catch (e) {
      print('Error al compartir PDF: $e');
      rethrow;
    }
  }
}
