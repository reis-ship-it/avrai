/// Message Search Bar Widget
/// 
/// Search bar for filtering/searching messages in chat
/// 
/// Phase 3 Enhancement: Message Search
/// Date: December 2025
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';

class MessageSearchBar extends StatefulWidget {
  final Function(String query) onSearch;
  final VoidCallback? onClear;
  
  const MessageSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
  });

  @override
  State<MessageSearchBar> createState() => _MessageSearchBarState();
}

class _MessageSearchBarState extends State<MessageSearchBar> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    widget.onSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearch('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _handleSearch,
            ),
          ),
        ],
      ),
    );
  }
}

