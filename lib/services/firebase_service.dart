// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_p_publica/models/hermano.dart';
import 'package:app_p_publica/models/territorio.dart';
import 'package:app_p_publica/models/horario.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  CollectionReference get hermanosCollection =>
      _firestore.collection('hermanos');
  CollectionReference get territoriosCollection =>
      _firestore.collection('territorios');
  CollectionReference get horariosCollection =>
      _firestore.collection('horarios');

  // Métodos para Hermanos
  Future<List<Hermano>> getHermanos() async {
    final snapshot = await hermanosCollection.get();
    return snapshot.docs.map((doc) {
      return Hermano.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  Future<void> addHermano(Hermano hermano) async {
    await hermanosCollection.add(hermano.toFirestore());
  }

  Future<void> updateHermano(Hermano hermano) async {
    await hermanosCollection.doc(hermano.id).update(hermano.toFirestore());
  }

  Future<void> deleteHermano(String id) async {
    // Primero eliminar los horarios asociados
    final horariosSnapshot =
        await horariosCollection.where('hermanoId', isEqualTo: id).get();

    final batch = _firestore.batch();
    for (var doc in horariosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(hermanosCollection.doc(id));
    await batch.commit();
  }

  // Métodos para Territorios
  Future<List<Territorio>> getTerritorios() async {
    final snapshot = await territoriosCollection.get();
    return snapshot.docs.map((doc) {
      return Territorio.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  Future<void> addTerritorio(Territorio territorio) async {
    await territoriosCollection.add(territorio.toFirestore());
  }

  Future<void> updateTerritorio(Territorio territorio) async {
    await territoriosCollection
        .doc(territorio.id)
        .update(territorio.toFirestore());
  }

  Future<void> deleteTerritorio(String id) async {
    // Primero eliminar los horarios asociados
    final horariosSnapshot =
        await horariosCollection.where('territorioId', isEqualTo: id).get();

    final batch = _firestore.batch();
    for (var doc in horariosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(territoriosCollection.doc(id));
    await batch.commit();
  }

  // Métodos para Horarios
  Future<List<Horario>> getHorarios() async {
    final snapshot = await horariosCollection.get();
    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;

        // Obtener información relacionada
        String? hermanoNombre;
        String? territorioNombre;

        try {
          final hermanoDoc =
              await hermanosCollection.doc(data['hermanoId']).get();
          if (hermanoDoc.exists) {
            // Crear objeto Hermano para usar nombreCompleto
            final hermanoData = hermanoDoc.data() as Map<String, dynamic>;
            final hermano = Hermano.fromFirestore(hermanoData, hermanoDoc.id);
            hermanoNombre = hermano.nombreCompleto;
          }

          final territorioDoc =
              await territoriosCollection.doc(data['territorioId']).get();
          if (territorioDoc.exists) {
            territorioNombre =
                (territorioDoc.data() as Map<String, dynamic>)['nombre'];
          }
        } catch (e) {
          print('Error al obtener información relacionada: $e');
        }

        data['hermanoNombre'] = hermanoNombre;
        data['territorioNombre'] = territorioNombre;

        return Horario.fromFirestore(data, doc.id);
      }).toList(),
    );
  }

  Future<List<Horario>> getHorariosByTerritorio(String territorioId) async {
    final snapshot =
        await horariosCollection
            .where('territorioId', isEqualTo: territorioId)
            .get();

    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;

        // Obtener nombre del hermano
        String? hermanoNombre;
        try {
          final hermanoDoc =
              await hermanosCollection.doc(data['hermanoId']).get();
          if (hermanoDoc.exists) {
            hermanoNombre =
                (hermanoDoc.data() as Map<String, dynamic>)['nombre'];
          }
        } catch (e) {
          print('Error al obtener información del hermano: $e');
        }

        data['hermanoNombre'] = hermanoNombre;
        data['territorioNombre'] = null; // Ya sabemos el territorio

        return Horario.fromFirestore(data, doc.id);
      }).toList(),
    );
  }

  Future<void> addHorario(Horario horario) async {
    await horariosCollection.add(horario.toFirestore());
  }

  Future<void> updateHorario(Horario horario) async {
    await horariosCollection.doc(horario.id).update(horario.toFirestore());
  }

  Future<void> deleteHorario(String id) async {
    await horariosCollection.doc(id).delete();
  }
}
