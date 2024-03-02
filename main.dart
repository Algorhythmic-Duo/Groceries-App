import 'package:flutter/material.dart';
import 'package:demoapp/database/datacode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SqliteApp());
}

class SqliteApp extends StatefulWidget {
  const SqliteApp({Key? key}) : super(key: key);

  @override
  State<SqliteApp> createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  final textController = TextEditingController();
  final searchController = TextEditingController();
  bool isSearching = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            isSearching ? 'Search Groceries' : 'Add Grocery',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        body: Center(
          child: Column(
            children: [
              if (isSearching)
                TextField(
                  controller: searchController,
                  style:
                      TextStyle(color: const Color.fromARGB(255, 7, 32, 255)),
                  decoration: InputDecoration(
                    labelText: 'Search groceries',
                    hintText: 'Enter a keyword',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'Enter grocery name',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.save),
                      onPressed: () async {
                        final enteredText = textController.text.trim();
                        if (enteredText.isNotEmpty) {
                          await DatabaseHelper.instance
                              .addGrocery(Grocery(name: enteredText));
                          setState(() {
                            textController.clear();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        final enteredText = textController.text.trim();
                        if (enteredText.isNotEmpty) {
                          await DatabaseHelper.instance.remove(enteredText);
                          setState(() {
                            textController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              Expanded(
                child: FutureBuilder<List<Grocery>>(
                  future: DatabaseHelper.instance
                      .getGroceries(isSearching ? searchController.text : ''),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Text('Loading...'));
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Error loading groceries!'),
                      );
                    }
                    return snapshot.data!.isEmpty
                        ? const Center(
                            child: Text('No  items found in the database.'))
                        : ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final grocery = snapshot.data![index];
                              return Center(
                                child: ListTile(
                                  title: Text(grocery.name,
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontSize: 20.0)),
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        floatingActionButton: FloatingActionButton(
          child: Icon(isSearching ? Icons.add : Icons.search),
          onPressed: () {
            setState(() {
              isSearching = !isSearching;
              if (!isSearching) {
                textController.clear();
                searchController.clear();
              }
            });
          },
        ),
      ),
    );
  }
}
