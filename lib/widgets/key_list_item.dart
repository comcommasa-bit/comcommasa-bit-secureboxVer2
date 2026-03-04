/// リストアイテムウィジェット
///
/// 一覧画面で表示するキーの単一アイテム。
/// タップすると詳細画面へ遷移する。
library;

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/key_model.dart';
import '../utils/helpers.dart';

/// キーリストの1行を表示するウィジェット
class KeyListItem extends StatelessWidget {
  /// 表示するキーデータ
  final KeyModel keyModel;

  /// タップ時のコールバック
  final VoidCallback onTap;

  /// [KeyListItem] を作成する
  const KeyListItem({
    super.key,
    required this.keyModel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData =
        AppConstants.categoryIcons[keyModel.category] ??
            Icons.vpn_key;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: 4.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppConstants.defaultRadius,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            iconData,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          keyModel.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${keyModel.category} • ${keyModel.type}'
          ' • ${Helpers.formatDateOnly(keyModel.updatedAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
