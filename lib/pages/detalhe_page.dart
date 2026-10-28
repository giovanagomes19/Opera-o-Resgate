import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/ocorrencia.dart';
import '../services/central_service.dart';

class DetalhePage extends StatefulWidget {
  final Ocorrencia ocorrencia;

  const DetalhePage({
    super.key,
    required this.ocorrencia,
  });

  @override
  State<DetalhePage> createState() => _DetalhePageState();
}

class _DetalhePageState extends State<DetalhePage> {
  final service = CentralService();
  final pista = TextEditingController();

  bool enviando = false;
  bool alterandoStatus = false;

  @override
  void dispose() {
    pista.dispose();
    super.dispose();
  }

  Future<void> enviar() async {
    final mensagem = pista.text.trim();

    if (mensagem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite uma pista antes de enviar.'),
        ),
      );
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre na sua conta para enviar uma pista.'),
        ),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await service.enviarPista(
        widget.ocorrencia.id,
        mensagem,
      );

      pista.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pista enviada com sucesso!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar pista: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  Future<void> alterarStatus() async {
    if (alterandoStatus) return;

    setState(() {
      alterandoStatus = true;
    });

    try {
      await service.alterarStatus(widget.ocorrencia);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível alterar o status: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          alterandoStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.ocorrencia;

    final usuarioAtual = FirebaseAuth.instance.currentUser;
    final dono = usuarioAtual != null && usuarioAtual.uid == o.autorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investigação'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              o.titulo,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Local: ${o.local}'),
            Text('Registrado por: ${o.autorNome}'),
            const SizedBox(height: 8),
            Text(
              o.descricao.isEmpty ? 'Sem descrição' : o.descricao,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${o.resolvido ? "Resolvido" : "Em aberto"}',
            ),
            if (dono)
              OutlinedButton.icon(
                onPressed: alterandoStatus ? null : alterarStatus,
                icon: const Icon(Icons.task_alt),
                label: Text(
                  alterandoStatus
                      ? 'Atualizando...'
                      : o.resolvido
                          ? 'Reabrir ocorrência'
                          : 'Marcar como resolvido',
                ),
              ),
            const Divider(),
            const Text(
              'Pistas da comunidade',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: service.pistas(o.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar pistas: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma pista ainda.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final dados = docs[index].data();

                      final mensagem =
                          dados['mensagem'] as String? ?? '';

                      final autor =
                          dados['autorNome'] as String? ?? 'Anônimo';

                      return ListTile(
                        leading: const Icon(Icons.lightbulb_outline),
                        title: Text(mensagem),
                        subtitle: Text(autor),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pista,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (!enviando) enviar();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Compartilhe uma pista...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: enviando ? null : enviar,
                  tooltip: 'Enviar pista',
                  icon: enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}