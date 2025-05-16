import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo para uma notificação
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  // Converte o modelo para um Map para armazenamento JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
      };

  // Cria um modelo a partir de um Map (JSON)
  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'],
        title: json['title'],
        body: json['body'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['isRead'],
      );
}

// Provider para gerenciar as notificações
class NotificationProvider with ChangeNotifier {
  static const String _notificationsKey = 'notifications';
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    loadNotifications(); // Chamada ao método público
  }

  // Carrega as notificações do SharedPreferences - AGORA PÚBLICO
  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? notificationsString = prefs.getString(_notificationsKey);
    if (notificationsString != null) {
      final List<dynamic> decodedJson = jsonDecode(notificationsString);
      _notifications = decodedJson.map((jsonItem) => NotificationModel.fromJson(jsonItem as Map<String, dynamic>)).toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
    notifyListeners();
  }

  // Salva as notificações no SharedPreferences (método interno, pode continuar privado)
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedJson = jsonEncode(_notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_notificationsKey, encodedJson);
  }

  // Adiciona uma nova notificação
  Future<void> addNotification(String title, String body) async {
    final newNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, newNotification);
    await _saveNotifications();
    notifyListeners();
  }

  // Marca uma notificação como lida
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  // Marca todas as notificações como lidas
  Future<void> markAllAsRead() async {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  // Limpa uma notificação específica
  Future<void> clearNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // Limpa todas as notificações
  Future<void> clearAllNotifications() async {
    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }
}

