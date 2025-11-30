import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/leaderboard/leaderboard_item.dart';
import '../../widgets/leaderboard/leaderboard_header.dart';

/// Leaderboard screen - Rankings and competition
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

    // Generate leaderboard with current user
    final entries = _generateLeaderboard();
    
    // Filter friends entries
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
    // Sample leaderboard data with current user
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

    // Add current user to the list
    final allEntries = [...baseEntries];
    allEntries.add(LeaderboardEntry(
      rank: 0, // Will be calculated
      username: _currentUsername,
      xp: _currentUserXp,
      level: (_currentUserXp ~/ 100) + 1,
      isCurrentUser: true,
    ));

    // Sort by XP and assign ranks
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
        appBar: AppBar(title: const Text('Ranking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Amigos'),
          ],
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
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                    },
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
                // Global leaderboard
                _buildLeaderboard(_entries),
                // Friends leaderboard
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
      return const Center(child: Text('Carregando ranking...'));
    }

    return CustomScrollView(
      slivers: [
        // Top 3 header
        SliverToBoxAdapter(
          child: LeaderboardHeader(
            first: entries[0],
            second: entries[1],
            third: entries[2],
          ),
        ),
        // Rest of the list
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = entries[index + 3]; // Skip top 3
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardItem(entry: entry),
                );
              },
              childCount: entries.length > 3 ? entries.length - 3 : 0,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddFriendDialog() async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Amigo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do usuário',
            hintText: 'Digite o nome do amigo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
        
        // Reload data
        await _loadLeaderboardData();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$result adicionado como amigo!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este usuário já é seu amigo')),
        );
      }
    }
  }

  Widget _buildFriendsLeaderboard() {
    if (_friendsEntries.length <= 1) {
      // Only current user, no friends
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Adicione amigos para competir!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddFriendDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Adicionar Amigos'),
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
            icon: const Icon(Icons.person_add),
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
                child: LeaderboardItem(entry: _friendsEntries[index]),
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
