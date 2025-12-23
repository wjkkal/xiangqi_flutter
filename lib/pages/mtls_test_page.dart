import 'package:flutter/material.dart';

/// mTLS 测试页面：已移除 mTLS 功能以保护私有信息
class MtlsTestPage extends StatelessWidget {
  const MtlsTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('mTLS 已移除'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('mTLS 功能已在开源版本中移除，以防止敏感配置和证书泄露。',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
