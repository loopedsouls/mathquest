import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/shop/duolingo_design_system.dart';

/// Leaderboard screen - Rankings and competition with Duolingo design
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  static const String _friendsKey = 'friends_list';
  
  late TabController _tabController;
  String _selectedFilter = 'Semanal';
  bool _isLoading = true;
  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> _friendsEntries = [];
  String _currentUsername = 'Estudante';
  int _currentUserXp = 0;

  final List<String> _filters = ['Diário', 'Semanal', 'Mensal', 'Geral'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUsername = prefs.getString('user_name') ?? 'Estudante';
    _currentUserXp = prefs.getInt('user_xp') ?? 0;
    final friendsList = prefs.getStringList(_friendsKey) ?? [];

    final entries = _generateLeaderboard();
    final friendsEntries = entries.where((e) => 
      friendsList.contains(e.username) || e.isCurrentUser
    ).toList();

    setState(() {
      _entries = entries;
      _friendsEntries = friendsEntries;
      _isLoading = false;
    });
  }

  List<LeaderboardEntry> _generateLeaderboard() {
    final baseEntries = [
      LeaderboardEntry(rank: 1, username: 'MathMaster', xp: 2450, level: 12, isCurrentUser: false),
      LeaderboardEntry(rank: 2, username: 'NumeroUno', xp: 2320, level: 11, isCurrentUser: false),
      LeaderboardEntry(rank: 3, username: 'AlgebraKing', xp: 2180, level: 10, isCurrentUser: false),
      LeaderboardEntry(rank: 4, username: 'GeometryGuru', xp: 1950, level: 9, isCurrentUser: false),
      LeaderboardEntry(rank: 5, username: 'MathWizard', xp: 1650, level: 7, isCurrentUser: false),
      LeaderboardEntry(rank: 6, username: 'Calculator', xp: 1500, level: 7, isCurrentUser: false),
      LeaderboardEntry(rank: 7, username: 'ProblemSolver', xp: 1350, level: 6, isCurrentUser: false),
      LeaderboardEntry(rank: 8, username: 'Estudioso', xp: 1200, level: 5, isCurrentUser: false),
      LeaderboardEntry(rank: 9, username: 'Aprendiz', xp: 1050, level: 5, isCurrentUser: false),
    ];

    final allEntries = [...baseEntries];
    allEntries.add(LeaderboardEntry(
      rank: 0,
      username: _currentUsername,
      xp: _currentUserXp,
      level: (_currentUserXp ~/ 100) + 1,
      isCurrentUser: true,
    ));

    allEntries.sort((a, b) => b.xp.compareTo(a.xp));
    for (int i = 0; i < allEntries.length; i++) {
      allEntries[i] = LeaderboardEntry(
        rank: i + 1,
        username: allEntries[i].username,
        xp: allEntries[i].xp,
        level: allEntries[i].level,
        isCurrentUser: allEntries[i].isCurrentUser,
        avatarUrl: allEntries[i].avatarUrl,
      );
    }

    return allEntries;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: DuoColors.bgDark,
        appBar: AppBar(
          backgroundColor: DuoColors.bgCard,
          title: const Text('Ranking', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator(color: DuoColors.yellow)),
      );
    }

    return Scaffold(
      backgroundColor: DuoColors.bgDark,
      appBar: AppBar(
        backgroundColor: DuoColors.bgCard,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DuoColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: DuoColors.yellow, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ranking',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: DuoColors.bgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: DuoColors.yellow,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: DuoColors.gray,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Global'),
                Tab(text: 'Amigos'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? DuoColors.yellow : DuoColors.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? DuoColors.yellow : DuoColors.bgElevated,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Leaderboard content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboard(_entries),
                _buildFriendsLeaderboard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(List<LeaderboardEntry> entries) {
    if (entries.length < 3) {
      return const Center(child: Text('Carregando ranking...', style: TextStyle(color: DuoColors.gray)));
    }

    return CustomScrollView(
      slivers: [
        // Top 3 header
        SliverToBoxAdapter(
          child: _buildPodiumHeader(entries[0], entries[1], entries[2]),
        ),
        // Rest of the list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index + 3];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildLeaderboardItem(entry),
                );
              },
              childCount: entries.length > 3 ? entries.length - 3 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumHeader(LeaderboardEntry first, LeaderboardEntry second, LeaderboardEntry third) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DuoColors.yellow.withValues(alpha: 0.3),
            DuoColors.bgDark,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumEntry(second, 2, 80),
          const SizedBox(width: 12),
          _buildPodiumEntry(first, 1, 100),
          const SizedBox(width: 12),
          _buildPodiumEntry(third, 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumEntry(LeaderboardEntry entry, int rank, double height) {
    Color medalColor;
    Color medalBg;
    switch (rank) {
      case 1:
        medalColor = const Color(0xFFFFD700);
        medalBg = const Color(0xFFFFD700).withValues(alpha: 0.2);
        break;
      case 2:
        medalColor = const Color(0xFFC0C0C0);
        medalBg = const Color(0xFFC0C0C0).withValues(alpha: 0.2);
        break;
      default:
        medalColor = const Color(0xFFCD7F32);
        medalBg = const Color(0xFFCD7F32).withValues(alpha: 0.2);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for #1
        if (rank == 1)
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 28),
        // Avatar
        Container(
          width: rank == 1 ? 64 : 52,
          height: rank == 1 ? 64 : 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 3),
            color: medalBg,
          ),
          child: Center(
            child: Text(
              entry.username[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 24 : 20,
                color: medalColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Username
        Text(
          entry.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        // XP
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: DuoColors.yellow, size: 14),
            Text(
              '${entry.xp}',
              style: TextStyle(
                color: DuoColors.gray.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                medalColor,
                medalColor.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser 
            ? DuoColors.green.withValues(alpha: 0.15)
            : DuoColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: entry.isCurrentUser
            ? Border.all(color: DuoColors.green, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: entry.isCurrentUser 
                  ? DuoColors.green.withValues(alpha: 0.2)
                  : DuoColors.bgElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: entry.isCurrentUser ? DuoColors.green : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isCurrentUser
                  ? DuoColors.green.withValues(alpha: 0.2)
                  : DuoColors.bgElevated,
              border: Border.all(
                color: entry.isCurrentUser ? DuoColors.green : DuoColors.gray.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                entry.username[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: entry.isCurrentUser ? DuoColors.green : DuoColors.gray,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.username,
                  style: TextStyle(
                    fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    color: entry.isCurrentUser ? DuoColors.green : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: DuoColors.yellow.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nível ${entry.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: DuoColors.gray.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? DuoColors.green.withValues(alpha: 0.2)
                  : DuoColors.yellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 16,
                  color: entry.isCurrentUser ? DuoColors.green : DuoColors.yellow,
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.xp}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: entry.isCurrentUser ? DuoColors.green : DuoColors.yellow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFriendDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DuoColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: DuoColors.green),
            SizedBox(width: 12),
            Text('Adicionar Amigo', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nome do usuário',
            hintText: 'Digite o nome do amigo',
            labelStyle: const TextStyle(color: DuoColors.gray),
            hintStyle: TextStyle(color: DuoColors.gray.withValues(alpha: 0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DuoColors.bgElevated),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DuoColors.bgElevated),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: DuoColors.green),
            ),
            filled: true,
            fillColor: DuoColors.bgElevated,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: DuoColors.gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final friends = prefs.getStringList(_friendsKey) ?? [];
      
      if (!friends.contains(result)) {
        friends.add(result);
        await prefs.setStringList(_friendsKey, friends);
        await _loadLeaderboardData();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$result adicionado como amigo!'),
            backgroundColor: DuoColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Este usuário já é seu amigo'),
            backgroundColor: DuoColors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildFriendsLeaderboard() {
    if (_friendsEntries.length <= 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DuoColors.blue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_rounded,
                size: 64,
                color: DuoColors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Adicione amigos para competir!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Convide seus colegas e vejam quem aprende mais.',
              style: TextStyle(
                color: DuoColors.gray.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: DuoColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Adicionar Amigos', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddFriendDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: DuoColors.bgCard,
              foregroundColor: DuoColors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: DuoColors.green),
              ),
            ),
            icon: const Icon(Icons.person_add_rounded, size: 20),
            label: const Text('Adicionar Amigo'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _friendsEntries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildLeaderboardItem(_friendsEntries[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Data class for leaderboard entry
class LeaderboardEntry {
  final int rank;
  final String username;
  final int xp;
  final String? avatarUrl;
  final int level;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.xp,
    this.avatarUrl,
    required this.level,
    required this.isCurrentUser,
  });
}
