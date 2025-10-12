# Módulo "Meu Perfil" - MathQuest

## Funcionalidades Implementadas

### 🎨 Sistema de Personalização de Personagem

O módulo "Meu Perfil" adiciona um sistema completo de personalização e gamificação ao MathQuest, incluindo:

#### 📋 Características Principais:

1. **Perfil do Personagem**

   - Nome personalizável
   - Sistema de níveis e experiência
   - Moedas virtuais para comprar itens
   - Visualização de progresso

2. **Sistema de Inventário**

   - Categorias de itens: Cabeça, Corpo, Pernas, Acessórios
   - Sistema de raridade (Comum, Raro, Épico, Lendário)
   - Itens equipáveis com preview visual
   - Filtros por categoria

3. **Loja de Itens**

   - Sistema de compra com moedas
   - Itens com condições de desbloqueio
   - Preços variáveis baseados na raridade
   - Sistema de recompensas automático

4. **Gamificação Avançada**
   - Desbloqueios automáticos baseados em conquistas
   - Sistema de recompensas por atividades
   - Progressão visual clara
   - Interface responsiva (Desktop/Mobile/Tablet)

### 🏗️ Arquitetura

#### Modelos de Dados:

- **`ItemPersonalizacao`**: Representa itens de customização
- **`PerfilPersonagem`**: Dados do perfil do usuário

#### Serviços:

- **`PersonagemService`**: Gerencia dados do personagem e inventário
  - Persistência usando SharedPreferences
  - Gestão de compras e equipamentos
  - Sistema de desbloqueios automáticos

#### Interface:

- **`PerfilScreen`**: Tela principal com 3 abas
  - **Personagem**: Preview e itens equipados
  - **Inventário**: Itens possuídos
  - **Loja**: Itens disponíveis para compra

### 🎯 Integração com Navegação

- Disponível apenas no desktop (como solicitado)
- Novo item na sidebar: "Meu Perfil"
- Ícone: `Icons.person`
- Posição: 5º item do menu

### 💰 Sistema Econômico

- **Moedas iniciais**: 500
- **Recompensas automáticas** por:
  - Completar exercícios
  - Subir de nível
  - Conquistar medalhas

### 🎁 Sistema de Desbloqueios

Itens podem ser desbloqueados por:

- **Nível do personagem**: "Atinja nível X"
- **Módulos completos**: "Complete X módulos"
- **Problemas corretos**: "Acerte X problemas"
- **Medalhas conquistadas**: "Ganhe X medalhas"

### 📱 Design Responsivo

- **Desktop**: Interface completa com sidebar
- **Tablet**: Otimizada para telas médias
- **Mobile**: Navegação por bottom bar (não inclui perfil)

### 🎨 Estilo Visual

- Design consistente com o tema dark do app
- Gradientes e sombras modernas
- Animações suaves
- Cores de raridade diferenciadas:
  - **Comum**: Cinza
  - **Raro**: Azul
  - **Épico**: Roxo
  - **Lendário**: Laranja

## 🚀 Como Usar

1. **Acesso**: No desktop, clique em "Meu Perfil" na sidebar
2. **Personalização**:
   - Aba "Personagem": Veja seu avatar e itens equipados
   - Aba "Inventário": Gerencie itens possuídos
   - Aba "Loja": Compre novos itens
3. **Edição**: Clique no ícone de edição para mudar o nome
4. **Equipar**: Clique em "Equipar" nos itens do inventário
5. **Comprar**: Use moedas para adquirir novos itens

## 📦 Arquivos Criados

- `lib/models/personagem.dart` - Modelos de dados
- `lib/services/personagem_service.dart` - Lógica de negócio
- `lib/screens/perfil_screen.dart` - Interface do usuário
- Atualização em `lib/screens/start_screen.dart` - Navegação
- Atualização em `pubspec.yaml` - Assets da pasta personagem

## 🎯 Próximas Melhorias (Opcionais)

- [ ] Sprites visuais reais para os itens
- [ ] Sistema de conjuntos (bonus por equipar itens combinados)
- [ ] Animações no preview do personagem
- [ ] Mais categorias de itens (armas, pets, etc.)
- [ ] Sistema de trocas entre usuários
- [ ] Galeria de personagens da comunidade

---

**Nota**: O módulo está totalmente integrado ao sistema existente e utiliza o mesmo padrão de design e arquitetura do projeto.
