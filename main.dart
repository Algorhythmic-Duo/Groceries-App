import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(isSearching ? 'Search Groceries' : 'Add Grocery'),
          backgroundColor: Colors.blueAccent,
        ),
        body: Center(
          child: Column(
            children: [
              if (isSearching)
                TextField(
                  controller: searchController,
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
                        ? const Center(child: Text('No grocery items found.'))
                        : ListView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final grocery = snapshot.data![index];
                              return Center(
                                child: ListTile(
                                  onLongPress: () async {
                                    try {
                                      await DatabaseHelper.instance
                                          .remove(grocery.id!);
                                      setState(() {});
                                    } catch (error) {
                                      print("Error removing grocery: $error");
                                    }
                                  },
                                  title: Text(grocery.name),
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

class Grocery {
  final int? id;
  final String name;

  Grocery({this.id, required this.name});

  factory Grocery.fromMap(Map<String, dynamic> json) => Grocery(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database == null) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'groceries.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async => await db.execute('''
        CREATE TABLE groceries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      '''),
    );
  }

  Future<List<Grocery>> getGroceries(String searchQuery) async {
    final db = await database;
    try {
      final groceries = await db.query('groceries',
          where: searchQuery.isNotEmpty ? 'name LIKE ?' : null,
          whereArgs: searchQuery.isNotEmpty ? ['%$searchQuery%'] : null,
          orderBy: 'name');
      return groceries.map((g) => Grocery.fromMap(g)).toList();
    } catch (error) {
      throw error;
    }
  }

  Future<int> addGrocery(Grocery grocery) async {
    final db = await database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
