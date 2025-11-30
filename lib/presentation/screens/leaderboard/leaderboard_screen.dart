import 'package:flutter/material.dart';
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
  late TabController _tabController;
  String _selectedFilter = 'Semanal';

  final List<String> _filters = ['Diário', 'Semanal', 'Mensal', 'Geral'];

  // Sample leaderboard data - TODO: Load from repository
  final List<LeaderboardEntry> _entries = [
    const LeaderboardEntry(
      rank: 1,
      username: 'MathMaster',
      xp: 2450,
      avatarUrl: null,
      level: 12,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 2,
      username: 'NumeroUno',
      xp: 2320,
      avatarUrl: null,
      level: 11,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 3,
      username: 'AlgebraKing',
      xp: 2180,
      avatarUrl: null,
      level: 10,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 4,
      username: 'GeometryGuru',
      xp: 1950,
      avatarUrl: null,
      level: 9,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 5,
      username: 'Estudante',
      xp: 1800,
      avatarUrl: null,
      level: 8,
      isCurrentUser: true,
    ),
    const LeaderboardEntry(
      rank: 6,
      username: 'MathWizard',
      xp: 1650,
      avatarUrl: null,
      level: 7,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 7,
      username: 'Calculator',
      xp: 1500,
      avatarUrl: null,
      level: 7,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 8,
      username: 'ProblemSolver',
      xp: 1350,
      avatarUrl: null,
      level: 6,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 9,
      username: 'Estudioso',
      xp: 1200,
      avatarUrl: null,
      level: 5,
      isCurrentUser: false,
    ),
    const LeaderboardEntry(
      rank: 10,
      username: 'Aprendiz',
      xp: 1050,
      avatarUrl: null,
      level: 5,
      isCurrentUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    return CustomScrollView(
      slivers: [
        // Top 3 header
        SliverToBoxAdapter(
          child: LeaderboardHeader(
            first: entries.isNotEmpty ? entries[0] : null,
            second: entries.length > 1 ? entries[1] : null,
            third: entries.length > 2 ? entries[2] : null,
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

  Widget _buildFriendsLeaderboard() {
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
            onPressed: () {
              // TODO: Implement add friends
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar Amigos'),
          ),
        ],
      ),
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

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.xp,
    this.avatarUrl,
    required this.level,
    required this.isCurrentUser,
  });
}
