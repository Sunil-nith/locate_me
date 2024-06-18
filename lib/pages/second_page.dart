import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:locate_me2/providers/user_details_provider.dart';

class SecondScreen extends StatefulWidget {
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
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() {
      Provider.of<UserDetailsProvider>(context, listen: false).fetchUserDetails();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPreviousPage() {
    final userDetailsProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    if (userDetailsProvider.currentPage > 1) {
      userDetailsProvider.fetchUserDetails(page: userDetailsProvider.currentPage - 1);
    }
  }

  void _loadNextPage() {
    final userDetailsProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    userDetailsProvider.fetchUserDetails(page: userDetailsProvider.currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsProvider = Provider.of<UserDetailsProvider>(context);
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
            child: _buildUserList(userDetailsProvider),
          ),
          _buildPaginationControls(userDetailsProvider),
        ],
      ),
    );
  }

  Widget _buildUserList(UserDetailsProvider userDetailsProvider) {
    if (userDetailsProvider.isLoading && userDetailsProvider.userData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (userDetailsProvider.hasError && userDetailsProvider.userData.isEmpty) {
      return const Center(child: Text('Failed to load user data'));
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: userDetailsProvider.userData.length + (userDetailsProvider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < userDetailsProvider.userData.length) {
            final user = userDetailsProvider.userData[index];
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

  Widget _buildPaginationControls(UserDetailsProvider userDetailsProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: userDetailsProvider.currentPage > 1 ? _loadPreviousPage : null,
            child: const Text('Previous Page'),
          ),
          const SizedBox(width: 16.0),
          ElevatedButton(
            onPressed: userDetailsProvider.isLoading ? null : _loadNextPage,
            child: const Text('Next Page'),
          ),
        ],
      ),
    );
  }
}
