import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class MeshDatabase {
  static final MeshDatabase instance = MeshDatabase._init();
  static Database? _database;
  
  final List<Map<String, dynamic>> _webMessages = [];
  final List<Map<String, dynamic>> _webNodes = [];

  MeshDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mesh_network.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN hops INTEGER DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const nullableTextType = 'TEXT';
    const nullableRealType = 'REAL';

    await db.execute('''
CREATE TABLE messages (
  messageId $idType,
  senderId $textType,
  receiverId $textType,
  content $textType,
  timestamp $integerType,
  ttl $integerType,
  hops $integerType,
  status $textType
  )
''');

    await db.execute('''
CREATE TABLE nodes (
  id $idType,
  name $nullableTextType,
  lastSeen $integerType,
  lat $nullableRealType,
  lng $nullableRealType
  )
''');
  }

  // Define basic CRUD operations here
  Future<void> insertMessage(Map<String, dynamic> message) async {
    if (kIsWeb) {
      _webMessages.removeWhere((m) => m['messageId'] == message['messageId']);
      _webMessages.add(message);
      return;
    }
    final db = await instance.database;
    await db.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllMessages() async {
    if (kIsWeb) {
      _webMessages.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      return List.from(_webMessages);
    }
    final db = await instance.database;
    return await db.query('messages', orderBy: 'timestamp ASC');
  }

  Future<List<Map<String, dynamic>>> getMessagesForChat(String peerId, String myId) async {
    if (kIsWeb) {
      final filtered = _webMessages.where((msg) {
        return (msg['senderId'] == myId && msg['receiverId'] == peerId) ||
               (msg['senderId'] == peerId && msg['receiverId'] == myId) ||
               (msg['receiverId'] == 'BROADCAST');
      }).toList();
      filtered.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      return filtered;
    }
    final db = await instance.database;
    // Messages where (sender = me and receiver = peer) OR (sender = peer and receiver = me) OR (receiver = BROADCAST)
    return await db.query(
      'messages',
      where: '(senderId = ? AND receiverId = ?) OR (senderId = ? AND receiverId = ?) OR receiverId = ?',
      whereArgs: [myId, peerId, peerId, myId, 'BROADCAST'],
      orderBy: 'timestamp ASC',
    );
  }

  Future<void> updateMessageStatus(String messageId, String status) async {
     if (kIsWeb) {
       final idx = _webMessages.indexWhere((m) => m['messageId'] == messageId);
       if (idx != -1) {
         _webMessages[idx] = Map<String, dynamic>.from(_webMessages[idx])..['status'] = status;
       }
       return;
     }
     final db = await instance.database;
     await db.update(
       'messages',
       {'status': status},
       where: 'messageId = ?',
       whereArgs: [messageId],
     );
  }

  Future<bool> messageExists(String messageId) async {
    if (kIsWeb) {
      return _webMessages.any((m) => m['messageId'] == messageId);
    }
    final db = await instance.database;
    final maps = await db.query(
      'messages',
      columns: ['messageId'],
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    return maps.isNotEmpty;
  }

  Future<void> upsertNode(Map<String, dynamic> node) async {
    if (kIsWeb) {
      _webNodes.removeWhere((n) => n['id'] == node['id']);
      _webNodes.add(node);
      return;
    }
    final db = await instance.database;
    await db.insert('nodes', node, conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<List<Map<String, dynamic>>> getAllNodes() async {
     if (kIsWeb) {
       _webNodes.sort((a, b) => (b['lastSeen'] as int).compareTo(a['lastSeen'] as int));
       return List.from(_webNodes);
     }
     final db = await instance.database;
     return await db.query('nodes', orderBy: 'lastSeen DESC');
  }

  Future<void> clearDatabase() async {
    if (kIsWeb) {
      _webMessages.clear();
      _webNodes.clear();
      return;
    }
    final db = await instance.database;
    await db.delete('messages');
    await db.delete('nodes');
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
