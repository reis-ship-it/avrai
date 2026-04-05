import 'package:flutter/material.dart';
import 'package:avrai_runtime_os/services/business/business_expert_chat_service_ai2ai.dart';
import 'package:avrai_runtime_os/services/business/business_business_chat_service_ai2ai.dart';
import 'package:avrai/theme/app_theme.dart';
import 'package:avrai/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/business/business_expert_chat_page.dart';
import 'package:intl/intl.dart';
import 'package:avrai/presentation/widgets/common/app_flow_scaffold.dart';

/// Business Conversations List Page
///
/// Lists all conversations (business-expert and business-business) for a business.
class BusinessConversationsListPage extends StatefulWidget {
  final String businessId;

  const BusinessConversationsListPage({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessConversationsListPage> createState() =>
      _BusinessConversationsListPageState();
}

class _BusinessConversationsListPageState
    extends State<BusinessConversationsListPage>
    with SingleTickerProviderStateMixin {
  final _expertChatService = GetIt.instance<BusinessExpertChatServiceAI2AI>();
  final _businessChatService =
      GetIt.instance<BusinessBusinessChatServiceAI2AI>();

  late TabController _tabController;
  List<Map<String, dynamic>> _expertConversations = [];
  List<Map<String, dynamic>> _businessConversations = [];
  bool _isLoading = true;
  final Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConversations();
    _loadUnreadCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load expert conversations
      final expertConvs =
          await _expertChatService.getBusinessConversations(widget.businessId);

      // Load business conversations
      final businessConvs = await _businessChatService
          .getBusinessConversations(widget.businessId);

      setState(() {
        _expertConversations = expertConvs;
        _businessConversations = businessConvs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final unreadCount = await _expertChatService.getUnreadCount(
        widget.businessId,
        true, // isBusiness
      );

      setState(() {
        _unreadCounts['experts'] = unreadCount;
      });

      final businessUnreadCount = await _businessChatService.getUnreadCount(
        widget.businessId,
      );

      setState(() {
        _unreadCounts['businesses'] = businessUnreadCount;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowScaffold(
      title: 'Conversations',
      backgroundColor: AppColors.grey50,
      appBarBackgroundColor: Colors.transparent,
      materialBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Experts'),
                if (_unreadCounts['experts'] != null &&
                    _unreadCounts['experts']! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_unreadCounts['experts']}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Businesses'),
                if (_unreadCounts['businesses'] != null &&
                    _unreadCounts['businesses']! > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_unreadCounts['businesses']}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExpertConversationsTab(),
          _buildBusinessConversationsTab(),
        ],
      ),
    );
  }

  Widget _buildExpertConversationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_expertConversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No conversations with experts yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting with experts to build partnerships',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _expertConversations.length,
        itemBuilder: (context, index) {
          final conversation = _expertConversations[index];
          return _buildConversationTile(
            conversation,
            isBusinessBusiness: false,
          );
        },
      ),
    );
  }

  Widget _buildBusinessConversationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_businessConversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No conversations with businesses yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Connect with other businesses for partnerships',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _businessConversations.length,
        itemBuilder: (context, index) {
          final conversation = _businessConversations[index];
          return _buildConversationTile(
            conversation,
            isBusinessBusiness: true,
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(
    Map<String, dynamic> conversation, {
    required bool isBusinessBusiness,
  }) {
    final conversationId = conversation['id'] as String;
    final lastMessageAt = conversation['last_message_at'] != null
        ? DateTime.parse(conversation['last_message_at'] as String)
        : null;
    final unreadCount = _unreadCounts[conversationId] ?? 0;

    String title;
    String? subtitle;

    if (isBusinessBusiness) {
      title = conversation['business_2_name'] as String? ?? 'Business';
      subtitle = conversation['business_1_name'] as String?;
    } else {
      title = conversation['expert_name'] as String? ?? 'Expert';
      subtitle = conversation['business_name'] as String?;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        child: Icon(
          isBusinessBusiness ? Icons.business : Icons.person,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle ?? '',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessageAt != null)
            Text(
              _formatTime(lastMessageAt),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        if (isBusinessBusiness) {
          // TODO: Navigate to business-business chat
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Business-business chat coming soon'),
            ),
          );
        } else {
          final expertId = conversation['expert_id'] as String?;
          if (expertId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusinessExpertChatPage(
                  businessId: widget.businessId,
                  expertId: expertId,
                  businessName: conversation['business_name'] as String?,
                  expertName: conversation['expert_name'] as String?,
                ),
              ),
            );
          }
        }
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MM/dd/yyyy').format(dateTime);
    }
  }
}
