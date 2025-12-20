import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:applamdep/providers/store_provider.dart';
import 'store_details.dart';

class StoreList extends StatefulWidget {
  const StoreList({super.key});

  @override
  _StoreListState createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<StoreProvider>(context, listen: false);
    provider.fetchUserLocation().then((_) => provider.fetchAllStores());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());
        if (provider.error != null) return Center(child: Text('Error: ${provider.error}'));
        return Scaffold(
          appBar: AppBar(title: const Text('All Salons')),
          body: ListView.builder(
            itemCount: provider.stores.length,
            itemBuilder: (context, index) {
              final store = provider.stores[index];
              return ListTile(
                leading: Image.network(store.imgUrl, width: 50, fit: BoxFit.cover),
                title: Text(store.name),
                subtitle: Text('${store.address} - Rating: ${store.rating}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoreDetails(storeId: store.id)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}