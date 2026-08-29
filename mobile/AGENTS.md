# mobile/ — AI エージェント向けガイド

Family Tap のアプリ本体（Expo / React Native）。日本語でやり取りすること（[../AGENTS.md](../AGENTS.md) 参照）。

## スタック

- Expo SDK 57 + **expo-router**（`app/` のファイルベースルーティング）+ TypeScript
- **NativeWind**（Tailwind CSS v3 の RN 版）でスタイリング — `className` を使う
- **TanStack Query**（`useQuery` / `useMutation`）でサーバーデータ
- **React Context**（`src/context/AuthContext` / `FamilyContext`）で全体状態
- `@supabase/supabase-js` v2

## ディレクトリ

```
app/                    画面（expo-router）
  _layout.tsx           プロバイダ + 認証/家族状態による画面ゲート（AuthGate）
  login / signup / family-gate
  family/create|join|members
  (tabs)/index|history|settings
  button/new|[id]        報告ボタンの作成・編集
  settings/display-name|family-name
src/
  lib/supabase.ts        Supabase クライアント（.env から URL/anon key）
  lib/japanCalendar.ts   JST の「今日」判定（DAILY ボタン用）
  services/              Supabase 呼び出し。1 ファイル = 1 ドメイン
  context/               AuthContext / FamilyContext
  hooks/useHome.ts       報告ボタン + DAILY 判定 + 報告 mutation + Realtime
  components/             共通 UI（見た目をいじるのは主にここ）
  components/ui/          Button / TextField / Screen
  types/models.ts        DB テーブルの型（supabase/migrations が真実）
```

## ルール

- **色・角丸**は `tailwind.config.js` の `theme.extend`（`brand` 色、`rounded-card/field/cell`）。
  ハードコードした hex を散らかさない
- ボタンの見た目は `src/components/ui/Button.tsx` 一箇所に集約
- ダークモード対応: `className="... dark:..."` を付ける（既存コードに倣う）
- 新しい画面は `app/` にファイルを足す。認証ゲートは `app/_layout.tsx` の `AuthGate` で
  制御しているので、グループ名を足したらそこの分岐も更新する
- Supabase のテーブル形状・RLS の挙動は `../supabase/migrations/` と `../PROGRESS.md` を確認。
  推測でクエリを書かない

## 変更前チェック

```bash
npx tsc --noEmit
npx expo lint
```

## 残タスク（../PROGRESS.md にも記載）

- Push 通知: Edge Function `../supabase/functions/send-family-notification` を APNs 直叩き →
  Expo Push API に書き換え。`src/services/push.ts` の token 登録は実装済み
- 通知設定画面
- ログイン以降の実データ通し確認
