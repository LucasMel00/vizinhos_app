import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatação de data
import 'package:vizinhos_app/screens/provider/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final notifications = notificationProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.mark_chat_read_outlined),
              tooltip: 'Marcar todas como lidas',
              onPressed: () {
                notificationProvider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Todas as notificações marcadas como lidas.')),
                );
              },
            ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Limpar todas as notificações',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar Notificações'),
                    content: const Text('Tem certeza que deseja limpar todas as notificações? Esta ação não pode ser desfeita.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Limpar Todas'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: () {
                          notificationProvider.clearAllNotifications();
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Todas as notificações foram limpas.')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma notificação no momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (ctx, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    child: const Icon(Icons.delete, color: Colors.white, size: 30),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) {
                    return showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Limpar Notificação'),
                        content: const Text('Tem certeza que deseja limpar esta notificação?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Não'),
                            onPressed: () {
                              Navigator.of(ctx).pop(false);
                            },
                          ),
                          TextButton(
                            child: const Text('Sim'),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: () {
                              Navigator.of(ctx).pop(true);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    notificationProvider.clearNotification(notification.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notificação "${notification.title}" limpa.')),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    elevation: 2,
                    child: ListTile(
                      leading: Icon(
                        notification.isRead ? Icons.notifications_off_outlined : Icons.notifications_active,
                        color: notification.isRead ? Colors.grey : Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: notification.isRead
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.mark_email_read_outlined, color: Colors.green),
                              tooltip: 'Marcar como lida',
                              onPressed: () {
                                notificationProvider.markAsRead(notification.id);
                              },
                            ),
                      onTap: () {
                        if (!notification.isRead) {
                          notificationProvider.markAsRead(notification.id);
                        }
                        // Poderia navegar para um detalhe da notificação se houvesse
                        // ou mostrar um dialogo com mais informações.
                        showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                  title: Text(notification.title),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(notification.body),
                                        const SizedBox(height: 10),
                                        Text(
                                          "Recebida em: ${DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp)}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Fechar'),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                    if (!notification.isRead)
                                      TextButton(
                                        child: const Text('Marcar como Lida'),
                                        onPressed: () {
                                          notificationProvider.markAsRead(notification.id);
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                  ],
                                ));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

