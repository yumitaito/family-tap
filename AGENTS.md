# Family Tap — AI エージェント向けガイド

このファイルは Codex など `AGENTS.md` を読むツール向け。Claude Code 用の `CLAUDE.md` と
同じ内容 + 補足。

## 言語ルール（重要）

このプロジェクトでのやり取りは、次の作業提案（follow-up suggestions）も含めて
**必ずすべて日本語**で行うこと。英語で出さない。コミットメッセージ・PR 本文・
コード内コメントも原則日本語（英語が慣例の技術用語はそのまま可）。

## プロジェクト概要

家族向けの「ワンタップ報告」アプリ。「犬にごはんあげた」等のボタンを家族で共有し、
誰かが押すと家族全員に記録・通知される。

- **`mobile/`** … アプリ本体（Expo / React Native）。**開発の中心はここ**。詳細は
  [`mobile/AGENTS.md`](mobile/AGENTS.md) と [`mobile/README.md`](mobile/README.md)
- **`supabase/`** … バックエンド（Postgres スキーマ・RLS・RPC・Edge Function）。
  マイグレーション適用済み・本番稼働中。**スキーマ変更は慎重に**（新規マイグレーションを
  追加する形で、既存ファイルは編集しない）
- **`FamilyTap/` `FamilyTap.xcodeproj` `project.yml`** … 旧 SwiftUI 版。Expo 版へ移行中で、
  実機確認が済んだら削除予定。**基本触らない**
- **`PROGRESS.md`** … これまでの経緯と残タスク。作業前に読むこと

## セットアップ（friend 向け）

```bash
cd mobile
npm install
# .env は git に入っていない。プロジェクトオーナーから Supabase の
# URL と anon key をもらって mobile/.env を作る（mobile/.env.example 参照）
npx expo start
```

Windows でも動く。スマホに **Expo Go** アプリを入れて QR を読むと実機で確認できる。

## 変更を出す前のチェック

```bash
cd mobile
npx tsc --noEmit     # 型
npx expo lint        # lint
```

## 触っていい / 慎重に

| 対象 | 方針 |
|---|---|
| `mobile/src/components/`, `mobile/app/**` の見た目 | 自由に改善 OK |
| `mobile/tailwind.config.js`（色・角丸） | OK |
| `mobile/src/services/`（Supabase 呼び出し） | ロジック変更は慎重に。テーブル形状は `supabase/migrations/` が真実 |
| `supabase/` | 新規マイグレーション追加のみ。既存 SQL は編集しない |
| `.env` | 絶対にコミットしない（gitignore 済み） |
