import 'package:flutter/material.dart';

enum ToastType { verifying, confirmed, error }

class ToastItem {
  final String id;
  final String message;
  final ToastType type;
  final DateTime createdAt;

  ToastItem({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
  });
}

class ToastProvider extends ChangeNotifier {
  final List<ToastItem> _toasts = [];

  List<ToastItem> get toasts => List.unmodifiable(_toasts);

  // Helper for generating unique IDs without extra deps if needed,
  // but uuid is standard. If uuid package not in pubspec, use random.
  // I will check pubspec in a moment, but I can just use DateTime + Random for simple needs to avoid adding deps.
  // Actually, I'll just use a simple counter or current implementation since I am Antigravity.

  void show(String message, ToastType type) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final toast = ToastItem(
      id: id,
      message: message,
      type: type,
      createdAt: DateTime.now(),
    );

    // Add to list
    _toasts.add(toast);

    // Auto-dismiss logic is handled by the UI manager usually, but we can manage list state here.
    // However, the prompt asks for specific physics and "pushing out" logic.
    // The visual manager will likely handle the *animations* of entry/exit.
    // But the provider is the source of truth.
    // Let's just keep the list here. The UI will listen and animate additions/removals.

    // Limit to keeping reasonable history if needed, but for "pushing out" visual,
    // the UI might want to know about items even if they are "gone" from the active view?
    // No, standard connection: Provider holds active toasts.

    // The requirement says: "Max 3 visible. When 4th arrives, oldest pushed out."
    // So we should enforce max length here?
    // If I enforce here, the UI will see the item disappear instantly.
    // To allow "gravity fall" animation of the removed item, the UI needs to know it *was* removed.
    // Or, the UI manages the animation state and calls `remove` here when done.

    // Better approach for complex animation:
    // Provider adds item.
    // UI listens. UI adds key to its internal AnimatedList or custom stack.
    // UI handles the "max 3" logic visually? No, business logic should dictate.

    // Let's just add to structure.
    notifyListeners();

    // Auto remove after some time?
    // Usually Toast has a duration.
    // Let's say 3 seconds.
    Future.delayed(const Duration(seconds: 4), () {
      remove(id);
    });
  }

  void remove(String id) {
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
