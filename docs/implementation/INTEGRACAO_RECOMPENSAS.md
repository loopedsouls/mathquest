# Como Integrar o Sistema de Recompensas - MathQuest

## 📋 Guia de Integração

Para integrar completamente o sistema de recompensas do personagem com as atividades do usuário, siga estes passos:

### 1. 🎯 Integração em Exercícios/Quiz

Adicione essas linhas após o usuário completar um exercício:

```dart
import '../services/recompensas_integration.dart';

// Após verificar se a resposta está correta
if (respostaCorreta) {
  await RecompensasIntegration.processarRecompensaExercicio(
    acertou: true,
    topico: 'álgebra', // ou o tópico atual
    dificuldade: 'médio', // 'fácil', 'médio', 'difícil'
  );

  // Verificar novos itens desbloqueados
  final novosItens = await RecompensasIntegration.verificarTodasRecompensas();
  if (novosItens.isNotEmpty) {
    // Mostrar notificação de novos itens
    _mostrarNotificacaoNovoItem(novosItens);
  }
}
```

### 2. 🏆 Integração em Módulos Completos

Quando um módulo for concluído:

```dart
// Após completar um módulo
await RecompensasIntegration.processarRecompensaModulo(
  moduloId: 'algebra_basica_6ano',
  pontuacao: 85.5, // Pontuação final do módulo
);

// Verificar desbloqueios
final novosItens = await RecompensasIntegration.verificarTodasRecompensas();
```

### 3. 🏅 Integração em Conquistas

Quando uma conquista/medalha for obtida:

```dart
import '../models/conquista.dart';

// Após ganhar uma conquista
await RecompensasIntegration.processarRecompensaConquista(
  conquistaId: conquista.id,
  pontosBonus: conquista.pontosBonus,
);
```

### 4. 📅 Login Diário (Streak)

No início do app ou na tela principal:

```dart
// Verificar se é um novo dia de login
final ultimoLogin = await SharedPreferences.getInstance()
    .then((prefs) => prefs.getString('ultimo_login'));

final hoje = DateTime.now().toString().substring(0, 10);

if (ultimoLogin != hoje) {
  // Calcular dias de sequência...
  int diasSequencia = calcularDiasSequencia();

  await RecompensasIntegration.processarRecompensaLoginDiario(
    diasSequencia: diasSequencia,
  );

  // Salvar novo login
  await prefs.setString('ultimo_login', hoje);
}
```

### 5. 🎨 Notificações de Novos Itens

Crie uma função para mostrar quando novos itens são desbloqueados:

```dart
void _mostrarNotificacaoNovoItem(List<String> novosItens) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          SizedBox(width: 8),
          Text('Novos Itens!'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Você desbloqueou:'),
          SizedBox(height: 8),
          ...novosItens.map((item) => Text('• $item')).toList(),
          SizedBox(height: 16),
          Text('Vá para "Meu Perfil" para ver seus novos itens!'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Legal!'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navegar para tela de perfil
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => PerfilScreen(),
            ));
          },
          child: Text('Ver Perfil'),
        ),
      ],
    ),
  );
}
```

### 6. 💰 Sistema de Moedas na Interface

Para mostrar as moedas do usuário em outras telas:

```dart
import '../services/personagem_service.dart';

class _MeuWidgetState extends State<MeuWidget> {
  int _moedas = 0;

  @override
  void initState() {
    super.initState();
    _carregarMoedas();
  }

  Future<void> _carregarMoedas() async {
    final perfil = PersonagemService().perfilAtual;
    setState(() {
      _moedas = perfil?.moedas ?? 0;
    });
  }

  Widget build(BuildContext context) {
    return AppBar(
      actions: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on, color: Colors.amber, size: 16),
              SizedBox(width: 4),
              Text('$_moedas', style: TextStyle(color: Colors.amber)),
            ],
          ),
        ),
      ],
    );
  }
}
```

### 7. 🎮 Gamificação Avançada

Para melhorar ainda mais a gamificação:

1. **Missões Diárias**: Crie objetivos específicos por dia
2. **Desafios Semanais**: Metas mais complexas
3. **Eventos Especiais**: Bonificações temporárias
4. **Rankings**: Compare com outros usuários
5. **Conquistas Secretas**: Itens especiais por ações inesperadas

### 8. 📱 Responsividade

O sistema já é responsivo, mas para mobile você pode:

1. Criar um widget "Moedas" compacto no AppBar
2. Mostrar notificações de nível como SnackBar
3. Adicionar animações de feedback visual

---

## 🚀 Exemplo Completo de Integração

Aqui está um exemplo de como integrar em uma tela de quiz:

```dart
class QuizScreen extends StatefulWidget {
  // ... seu código existente
}

class _QuizScreenState extends State<QuizScreen> {
  // ... suas variáveis existentes

  Future<void> _processarResposta(bool acertou) async {
    // Sua lógica de verificação de resposta...

    if (acertou) {
      // Processar recompensas
      await RecompensasIntegration.processarRecompensaExercicio(
        acertou: true,
        topico: widget.topico,
        dificuldade: widget.dificuldade,
      );

      // Verificar novos desbloqueios
      final novosItens = await RecompensasIntegration.verificarTodasRecompensas();

      if (novosItens.isNotEmpty) {
        // Mostrar com delay para não interferir na resposta
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _mostrarNotificacaoNovoItem(novosItens);
          }
        });
      }
    }
  }
}
```

Seguindo este guia, o sistema de personalização estará completamente integrado com a experiência de aprendizado do usuário!
