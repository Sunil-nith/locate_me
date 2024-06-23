import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locate_me2/providers/user_details_provider.dart';

class SecondScreen extends ConsumerStatefulWidget {
  final String startLoc;
  final String endLoc;
  final double totalDistance;

  const SecondScreen({
    super.key,
    required this.startLoc,
    required this.endLoc,
    required this.totalDistance,
  });

  @override
  ConsumerState<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends ConsumerState<SecondScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() {
      ref.read(userDetailsProvider.notifier).fetchUserDetails();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPreviousPage() {
    final userDetailsState = ref.read(userDetailsProvider);
    if (userDetailsState.currentPage > 1) {
      ref
          .read(userDetailsProvider.notifier)
          .fetchUserDetails(page: userDetailsState.currentPage - 1);
    }
  }

  void _loadNextPage() {
    final userDetailsState = ref.read(userDetailsProvider);
    ref
        .read(userDetailsProvider.notifier)
        .fetchUserDetails(page: userDetailsState.currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsState = ref.watch(userDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocateMe'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Location: ${widget.startLoc}',
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 10),
                Text(
                  'End Location: ${widget.endLoc}',
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 10),
                Text(
                  'Total Distance: ${widget.totalDistance.toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 18.0),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildUserList(userDetailsState),
          ),
          _buildPaginationControls(userDetailsState),
        ],
      ),
    );
  }

  Widget _buildUserList(UserDetailsState userDetailsState) {
    if (userDetailsState.isLoading &&
        userDetailsState
                .userDataPerPage[userDetailsState.currentPage]?.isEmpty ==
            true) {
      return const Center(child: CircularProgressIndicator());
    } else if (userDetailsState.hasError &&
        userDetailsState
                .userDataPerPage[userDetailsState.currentPage]?.isEmpty ==
            true) {
      return const Center(child: Text('Failed to load user data'));
    } else if (userDetailsState
            .userDataPerPage[userDetailsState.currentPage]?.isEmpty ==
        true) {
      return const Center(child: Text('No data available'));
    } else {
      final users =
          userDetailsState.userDataPerPage[userDetailsState.currentPage] ?? [];
      return ListView.builder(
        controller: _scrollController,
        itemCount: users.length + (userDetailsState.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < users.length) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(user.avatar),
              ),
              title: Text('${user.first_name} ${user.last_name}'),
              subtitle: Text(user.email),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }
  }

  Widget _buildPaginationControls(UserDetailsState userDetailsState) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed:
                userDetailsState.currentPage > 1 ? _loadPreviousPage : null,
            child: const Text('Previous Page'),
          ),
          const SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: userDetailsState.isLoading ? null : _loadNextPage,
            child: const Text('Next Page'),
          ),
        ],
      ),
    );
  }
}
