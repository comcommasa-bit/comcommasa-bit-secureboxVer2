/// 詳細カードウィジェット
///
/// キーの全情報を表示する。
/// タップでコピー、長押しで3秒間値を表示する。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../utils/helpers.dart';
import 'toast.dart';

/// キー詳細情報を表示するカード
class KeyDetailCard extends StatefulWidget {
  /// 表示するキーデータ
  final KeyModel keyModel;

  /// [KeyDetailCard] を作成する
  const KeyDetailCard({super.key, required this.keyModel});

  @override
  State<KeyDetailCard> createState() => _KeyDetailCardState();
}

class _KeyDetailCardState extends State<KeyDetailCard> {
  bool _isValueVisible = false;

  /// 値をクリップボードにコピーする
  Future<void> _copyValue() async {
    await Clipboard.setData(
      ClipboardData(text: widget.keyModel.value),
    );
    if (mounted) {
      AppToast.showSuccess(context, 'コピーしました');
    }
  }

  /// 値を3秒間表示してから隠す
  void _showValueTemporarily() {
    setState(() => _isValueVisible = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isValueVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconData =
        AppConstants.categoryIcons[widget.keyModel.category] ??
            Icons.vpn_key;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppConstants.defaultRadius,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー（アイコン + 名前）
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Icon(
                    iconData,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.keyModel.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // カテゴリ・種類
            _buildInfoRow('カテゴリ', widget.keyModel.category),
            _buildInfoRow('種類', widget.keyModel.type),

            // ユーザー名・メールアドレス
            if (widget.keyModel.username != null &&
                widget.keyModel.username!.isNotEmpty)
              _buildInfoRow('ユーザー名', widget.keyModel.username!),
            if (widget.keyModel.email != null &&
                widget.keyModel.email!.isNotEmpty)
              _buildInfoRow('メール', widget.keyModel.email!),

            const SizedBox(height: 12),

            // キー値（タップでコピー / 長押しで表示）
            Text(
              'キー値',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _copyValue,
              onLongPress: _showValueTemporarily,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isValueVisible
                            ? widget.keyModel.value
                            : Helpers.maskText(
                                widget.keyModel.value,
                              ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'タップでコピー / 長押しで3秒表示',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // メモ
            if (widget.keyModel.memo != null &&
                widget.keyModel.memo!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow('メモ', widget.keyModel.memo!),
            ],

            const Divider(height: 24),

            // 日時情報
            _buildInfoRow(
              '作成日',
              Helpers.formatDate(widget.keyModel.createdAt),
            ),
            _buildInfoRow(
              '更新日',
              Helpers.formatDate(widget.keyModel.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  /// 情報行を構築する
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
