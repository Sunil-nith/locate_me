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
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() {
      ref.read(userDetailsProvider(currentPage).notifier).fetchUserDetails();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPreviousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      ref.read(userDetailsProvider(currentPage).notifier).fetchUserDetails();
    }
  }

  void _loadNextPage() {
    setState(() {
      currentPage++;
    });
    ref.read(userDetailsProvider(currentPage).notifier).fetchUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsState = ref.watch(userDetailsProvider(currentPage));

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
    if (userDetailsState is LoadingUserDetailsState) {
      return const Center(child: CircularProgressIndicator());
    } else if (userDetailsState is ErrorUserDetailsState) {
      return Center(child: Text(userDetailsState.errorMessage));
    } else if (userDetailsState is LoadedUserDetailsState) {
      final users = userDetailsState.users;
      return ListView.builder(
        controller: _scrollController,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user.avatar),
            ),
            title: Text('${user.first_name} ${user.last_name}'),
            subtitle: Text(user.email),
          );
        },
      );
    } else {
      return const Center(child: Text('No data available'));
    }
  }

  Widget _buildPaginationControls(UserDetailsState userDetailsState) {
  bool isLastPage =
      userDetailsState is LoadedUserDetailsState &&
      userDetailsState.users.isEmpty;

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: currentPage > 1 ? _loadPreviousPage : null,
          child: const Text('Previous Page'),
        ),
        const SizedBox(width: 16.0),
        ElevatedButton(
          onPressed: isLastPage || userDetailsState is LoadingUserDetailsState
              ? null
              : _loadNextPage,
          child: Text(
            isLastPage ? 'Last Page' : 'Next Page',
          ),
        ),
      ],
    ),
  );
}

}
