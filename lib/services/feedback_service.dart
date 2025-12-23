import 'package:flutter/material.dart';

/// 意见反馈服务（开源版）：不再上传到服务器，仅在本地记录并返回成功。
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  /// 提交用户反馈（本地处理）
  Future<Map<String, dynamic>> submitFeedback({
    String? category,
    String? title,
    String? contact,
    required String content,
  }) async {
    try {
      debugPrint('📩 本地记录用户反馈（未上传）');
      debugPrint('分类: ${category ?? "未设置"}');
      debugPrint('标题: ${title ?? "未设置"}');
      debugPrint('内容: $content');

      // TODO: 若需要，可将反馈写入本地文件或使用 shared_preferences 保存

      return {
        'success': true,
        'message': '反馈已本地记录（未上传）',
      };
    } catch (e) {
      debugPrint('❌ 本地记录反馈失败: $e');
      return {
        'success': false,
        'message': '本地处理失败: $e',
      };
    }
  }
}
