import 'package:flutter/material.dart';
import '../services/feedback_service.dart';
import '../utils/snackbar_helper.dart';

/// 意见反馈页面
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _titleController = TextEditingController();
  final _contactController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contactController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 提交反馈
  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 提交反馈（仅本地处理）
      final result = await FeedbackService().submitFeedback(
        category: '5', // 默认分类
        title: _titleController.text.trim(),
        contact: _contactController.text.trim(),
        content: _contentController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
          // 提交成功
          SnackBarHelper.show(
              context,
              SnackBar(
                content: Text(result['message'] ?? '反馈提交成功'),
                backgroundColor: Colors.green,
              ));
          // 返回上一页
          Navigator.of(context).pop();
        } else {
          // 提交失败
          SnackBarHelper.show(
              context,
              SnackBar(
                content: Text('提交失败: ${result['message']}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ));
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(
            context,
            SnackBar(
              content: Text('提交异常: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('意见反馈'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 标题输入框
            TextFormField(
              controller: _titleController,
              maxLength: 64,
              decoration: const InputDecoration(
                labelText: '标题（可选）',
                hintText: '请输入反馈标题',
                border: OutlineInputBorder(),
                counterText: '', // 隐藏字符计数器
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),

            // 内容输入框
            TextFormField(
              controller: _contentController,
              maxLength: 1024,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: '反馈内容 *',
                hintText: '请详细描述您的意见或建议',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '反馈内容不能为空';
                }
                return null;
              },
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 12),

            // 联系方式输入框（可选）
            TextFormField(
              controller: _contactController,
              maxLength: 32,
              decoration: const InputDecoration(
                labelText: '联系方式（可选）',
                hintText: '可填写手机号、邮箱或QQ等联系方式',
                border: OutlineInputBorder(),
                counterText: '', // 隐藏字符计数器
              ),
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 24),

            // 按钮行
            Row(
              children: [
                // 取消按钮
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),

                // 提交按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('提交'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
