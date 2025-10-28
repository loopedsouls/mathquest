import 'package:flutter/material.dart';
import 'package:mathquest/screens/forum_post.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidade'),
      ),
      body: ListView(
        children: const [
          ForumPost(
              author: "User1",
              content: "Como converter uma função para gráfico?"),
          ForumPost(
              author: "User2",
              content: "Qual a interpretação geométrica da derivada?"),
        ],
      ),
    );
  }
}
