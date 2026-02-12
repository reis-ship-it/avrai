/// Unified Chat Page
///
/// Provides a unified interface for:
/// - Personality Agent Chat (AI companion)
/// - Friends Chats (1-on-1)
/// - Community/Club Chats (group)
///
/// Phase 3: Unified Chat UI Implementation
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/pages/chat/agent_chat_view.dart';
import 'package:avrai/presentation/pages/chat/friends_chat_list_view.dart';
import 'package:avrai/presentation/pages/chat/communities_chat_list_view.dart';
import 'package:avrai/presentation/widgets/adaptive/adaptive_layout.dart';

class UnifiedChatPage extends StatefulWidget {
  final int initialTabIndex;
  final String? initialChatId; // For deep linking to specific chat

  const UnifiedChatPage({
    super.key,
    this.initialTabIndex = 0,
    this.initialChatId,
  });

  @override
  State<UnifiedChatPage> createState() => _UnifiedChatPageState();
}

class _UnifiedChatPageState extends State<UnifiedChatPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdaptivePlatformPageScaffold(
      title: 'Chat',
      constrainBody: false,
      appBarBackgroundColor: AppTheme.primaryColor,
      appBarForegroundColor: AppColors.white,
      materialBottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.white,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.smart_toy),
            text: 'Agent',
          ),
          Tab(
            icon: Icon(Icons.person),
            text: 'Friends',
          ),
          Tab(
            icon: Icon(Icons.group),
            text: 'Communities',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AgentChatView(),
          FriendsChatListView(),
          CommunitiesChatListView(),
        ],
      ),
    );
  }
}
