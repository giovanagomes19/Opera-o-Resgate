import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ocorrencia.dart';

class CentralService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Stream<List<Ocorrencia>> acompanhar() {
    return _db
        .collection('ocorrencias')
        .orderBy('criadoEm', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Ocorrencia.fromDoc(doc))
              .toList(),
        );
  }

  Future<void> registrar({
    required String titulo,
    required String local,
    required String descricao,
  }) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw StateError('Você precisa entrar na sua conta para registrar.');
    }

    if (titulo.trim().isEmpty || local.trim().isEmpty) {
      throw ArgumentError('O título e o local são obrigatórios.');
    }

    await _db.collection('ocorrencias').add({
      'titulo': titulo.trim(),
      'local': local.trim(),
      'descricao': descricao.trim(),
      'autorId': usuario.uid,
      'autorNome': usuario.displayName ??
          usuario.email ??
          'Anônimo',
      'resolvido': false,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

 
  Future<void> alterarStatus(Ocorrencia item) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw StateError('Você precisa entrar na sua conta.');
    }

    if (usuario.uid != item.autorId) {
      throw StateError(
        'Apenas o responsável pela ocorrência pode alterar o status.',
      );
    }

    await _db
        .collection('ocorrencias')
        .doc(item.id)
        .update({
      'resolvido': !item.resolvido,
    });
  }

 
  Future<void> enviarPista(
    String ocorrenciaId,
    String mensagem,
  ) async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw StateError('Você precisa entrar na sua conta para enviar pistas.');
    }

    if (mensagem.trim().isEmpty) {
      throw ArgumentError('A mensagem da pista não pode estar vazia.');
    }

    final ocorrencia = _db
        .collection('ocorrencias')
        .doc(ocorrenciaId);

    final documento = await ocorrencia.get();

    if (!documento.exists) {
      throw StateError('A ocorrência não foi encontrada.');
    }

    await ocorrencia.collection('pistas').add({
      'mensagem': mensagem.trim(),
      'autorId': usuario.uid,
      'autorNome': usuario.displayName ??
          usuario.email ??
          'Anônimo',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  
  Stream<QuerySnapshot<Map<String, dynamic>>> pistas(String id) {
    return _db
        .collection('ocorrencias')
        .doc(id)
        .collection('pistas')
        .orderBy('criadoEm', descending: false)
        .snapshots();
  }
}