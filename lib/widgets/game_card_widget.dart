import 'package:flutter/material.dart';

class GameCard extends StatelessWidget {
  final String title;
  final String version; // e.g. "DX" or "SUN PLUS"
  final Color color;
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onSync;

  const GameCard({
    super.key,
    required this.title,
    required this.version,
    required this.color,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        version,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isLoggedIn ? Icons.check_circle : Icons.error_outline,
                    color: isLoggedIn ? Colors.greenAccent : Colors.white54,
                    size: 32,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoggedIn ? onSync : onLogin,
                      icon: Icon(isLoggedIn ? Icons.sync : Icons.login),
                      label: Text(isLoggedIn ? '一键同步' : '登录授权'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color, // 按钮文字颜色跟随卡片主题
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
