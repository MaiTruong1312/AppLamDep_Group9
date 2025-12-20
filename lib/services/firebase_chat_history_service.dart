// services/firebase_chat_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FirebaseChatHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ================== GET CURRENT USER ==================
  static String? get currentUserId {
    return _auth.currentUser?.uid;
  }

  // ================== GET USER CHATS STREAM ==================
  static Stream<QuerySnapshot> getUserChatsStream({
    String? userId,
    int limit = 20,
    bool showArchived = false,
    bool showDeleted = false,
  }) {
    final uid = userId ?? currentUserId;
    if (uid == null) {
      return const Stream.empty();
    }

    Query query = _firestore
        .collection('nail_chatbot_chats')
        .where('userId', isEqualTo: uid)
        .orderBy('chatInfo.updatedAt', descending: true)
        .limit(limit);

    if (!showArchived) {
      query = query.where('isArchived', isEqualTo: false);
    }

    if (!showDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }

    return query.snapshots();
  }

  // ================== GET CHAT DETAILS ==================
  static Future<DocumentSnapshot> getChatDetails(String chatId) async {
    return await _firestore
        .collection('nail_chatbot_chats')
        .doc(chatId)
        .get();
  }

  // ================== GET CHAT MESSAGES ==================
  static Stream<QuerySnapshot> getChatMessagesStream(
      String chatId, {
        int limit = 50,
      }) {
    return _firestore
        .collection('nail_chatbot_messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp.sentAt', descending: false)
        .limit(limit)
        .snapshots();
  }

  // ================== LOAD SPECIFIC CHAT ==================
  static Future<List<Map<String, dynamic>>> loadChatMessages(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('nail_chatbot_messages')
          .where('chatId', isEqualTo: chatId)
          .orderBy('timestamp.sentAt')
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp']?['sentAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('Error loading chat messages: $e');
      return [];
    }
  }

  // ================== UPDATE CHAT METADATA ==================
  static Future<void> updateChatMetadata({
    required String chatId,
    String? title,
    bool? isStarred,
    bool? isArchived,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'chatInfo.updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['chatInfo.title'] = title;
      if (isStarred != null) updateData['isStarred'] = isStarred;
      if (isArchived != null) updateData['isArchived'] = isArchived;
      if (tags != null) updateData['tags'] = tags;

      await _firestore
          .collection('nail_chatbot_chats')
          .doc(chatId)
          .update(updateData);
    } catch (e) {
      print('Error updating chat metadata: $e');
      rethrow;
    }
  }

  // ================== SOFT DELETE CHAT ==================
  static Future<void> softDeleteChat(String chatId) async {
    try {
      await _firestore
          .collection('nail_chatbot_chats')
          .doc(chatId)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'chatInfo.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error soft deleting chat: $e');
      rethrow;
    }
  }
  // ================== SAVE MESSAGE ==================
  static Future<void> saveMessage({
    required String chatId,
    required String text,
    required String role, // 'user' hoặc 'ai'
    String type = 'text',
  }) async {
    try {
      // 1. Lưu tin nhắn vào collection messages
      await _firestore.collection('nail_chatbot_messages').add({
        'chatId': chatId,
        'content': {
          'text': text,
          'type': type,
        },
        'sender': {
          'type': role,
        },
        'timestamp': {
          'sentAt': FieldValue.serverTimestamp(),
        },
      });

      // 2. Cập nhật thông tin chat (tin nhắn cuối, thời gian update, số lượng tin)
      await _firestore.collection('nail_chatbot_chats').doc(chatId).update({
        'lastMessage': text,
        'chatInfo.updatedAt': FieldValue.serverTimestamp(),
        'statistics.totalMessages': FieldValue.increment(1),
        if (role == 'user') 'statistics.userMessages': FieldValue.increment(1),
        if (role == 'ai') 'statistics.aiMessages': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error saving message: $e');
      rethrow;
    }
  }

  // ================== PERMANENTLY DELETE CHAT ==================
  static Future<void> permanentlyDeleteChat(String chatId) async {
    try {
      // Xóa tất cả messages của chat
      final messagesSnapshot = await _firestore
          .collection('nail_chatbot_messages')
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _firestore.batch();

      // Xóa từng message
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Xóa chat document
      batch.delete(_firestore.collection('nail_chatbot_chats').doc(chatId));

      await batch.commit();
    } catch (e) {
      print('Error permanently deleting chat: $e');
      rethrow;
    }
  }

  // ================== RESTORE CHAT ==================
  static Future<void> restoreChat(String chatId) async {
    try {
      await _firestore
          .collection('nail_chatbot_chats')
          .doc(chatId)
          .update({
        'isDeleted': false,
        'deletedAt': null,
        'chatInfo.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error restoring chat: $e');
      rethrow;
    }
  }

  // ================== CREATE NEW CHAT ==================
  static Future<String> createNewChat({
    required String userId,
    String? title,
    List<String> tags = const [],
  }) async {
    try {
      final chatRef = _firestore.collection('nail_chatbot_chats').doc();
      final chatId = chatRef.id;

      final chatData = {
        'chatId': chatId,
        'userId': userId,
        'chatInfo': {
          'title': title ?? 'Cuộc trò chuyện mới',
          'description': '',
          'category': 'general',
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'duration': 0,
        },
        'aiConfig': {
          'personality': 'friendly',
          'model': 'gpt-4',
          'temperature': 0.7,
          'maxTokens': 1000,
        },
        'participants': {
          'user': {
            'userId': userId,
            'name': 'Người dùng',
            'role': 'customer',
          },
          'ai': {
            'id': 'nail_assistant_ai',
            'name': 'Nail Assistant AI',
            'role': 'assistant',
            'version': '1.2.3',
          }
        },
        'statistics': {
          'totalMessages': 0,
          'userMessages': 0,
          'aiMessages': 0,
          'hasImages': false,
          'hasVoice': false,
          'hasAnalysis': false,
          'wordCount': 0,
        },
        'tags': tags,
        'metadata': {
          'device': 'flutter_app',
          'appVersion': '1.0.0',
        },
        'isArchived': false,
        'isStarred': false,
        'isDeleted': false,
        'deletedAt': null,
      };

      await chatRef.set(chatData);
      return chatId;
    } catch (e) {
      print('Error creating new chat: $e');
      rethrow;
    }
  }

  // ================== SEARCH CHATS ==================
  static Stream<QuerySnapshot> searchChats({
    required String userId,
    required String query,
    int limit = 20,
  }) {
    // Firebase Firestore không hỗ trợ text search trực tiếp
    // Có thể implement với Algolia hoặc dùng array-contains cho tags
    return _firestore
        .collection('nail_chatbot_chats')
        .where('userId', isEqualTo: userId)
        .where('chatInfo.title', isGreaterThanOrEqualTo: query)
        .where('chatInfo.title', isLessThanOrEqualTo: '$query\uf8ff')
        .orderBy('chatInfo.title')
        .limit(limit)
        .snapshots();
  }

  // ================== GET USER STATISTICS ==================
  static Future<Map<String, dynamic>> getUserChatStatistics(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('nail_chatbot_chats')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      int totalChats = chatsSnapshot.docs.length;
      int totalMessages = 0;
      int starredChats = 0;
      int archivedChats = 0;

      for (var doc in chatsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalMessages += (data['statistics']?['totalMessages'] as int? ?? 0);
        if (data['isStarred'] == true) starredChats++;
        if (data['isArchived'] == true) archivedChats++;
      }

      return {
        'totalChats': totalChats,
        'totalMessages': totalMessages,
        'starredChats': starredChats,
        'archivedChats': archivedChats,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'totalChats': 0,
        'totalMessages': 0,
        'starredChats': 0,
        'archivedChats': 0,
        'lastUpdated': DateTime.now(),
      };
    }
  }
}