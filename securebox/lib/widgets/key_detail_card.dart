import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../utils/helpers.dart';
import 'toast.dart';

/// キー詳細表示カードウィジェット
class KeyDetailCard extends StatefulWidget {
  /// 表示するキーデータ
  final KeyModel keyData;

  const KeyDetailCard({
    super.key,
    required this.keyData,
  });

  @override
  State<KeyDetailCard> createState() => _KeyDetailCardState();
}

class _KeyDetailCardState extends State<KeyDetailCard> {
  bool _isValueVisible = false;

  /// キー値をクリップボードにコピー
  Future<void> _copyValue() async {
    await Clipboard.setData(ClipboardData(text: widget.keyData.value));
    if (mounted) {
      Toast.success(context, 'コピーしました');
    }
  }

  /// 値の表示/非表示を切り替え（3秒後に自動で非表示）
  void _toggleValueVisibility() {
    setState(() {
      _isValueVisible = !_isValueVisible;
    });

    if (_isValueVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isValueVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryName =
        Constants.categoryNames[widget.keyData.category] ??
            widget.keyData.category;
    final typeName =
        Constants.keyTypeNames[widget.keyData.type] ?? widget.keyData.type;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // キー名
            Text(
              widget.keyData.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.keyData.furigana != null &&
                widget.keyData.furigana!.isNotEmpty)
              Text(
                widget.keyData.furigana!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            const Divider(height: 24),

            // カテゴリ・タイプ
            _buildInfoRow('カテゴリ', categoryName),
            const SizedBox(height: 8),
            _buildInfoRow('種類', typeName),
            const SizedBox(height: 16),

            // キー値
            Row(
              children: [
                Text(
                  'キー値',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _isValueVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: _toggleValueVisibility,
                  tooltip: _isValueVisible ? '非表示' : '表示',
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: _copyValue,
                  tooltip: 'コピー',
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _isValueVisible
                    ? widget.keyData.value
                    : Helpers.maskValue(widget.keyData.value),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),

            // メモ
            if (widget.keyData.memo != null &&
                widget.keyData.memo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow('メモ', widget.keyData.memo!),
            ],

            // 日時
            const Divider(height: 24),
            _buildInfoRow(
              '作成日',
              Helpers.formatDateTime(widget.keyData.createdAt),
            ),
            if (widget.keyData.updatedAt != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(
                '更新日',
                Helpers.formatDateTime(widget.keyData.updatedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
