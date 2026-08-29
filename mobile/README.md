# Family Tap — モバイルアプリ（Expo / React Native）

SwiftUI 版からの移行先。バックエンド（Supabase）は `../supabase/` をそのまま共有する。

## 技術スタック

| 領域 | 採用 |
|---|---|
| フレームワーク | Expo SDK 57 + expo-router（ファイルベースルーティング）+ TypeScript |
| バックエンド接続 | `@supabase/supabase-js` v2 |
| スタイリング | NativeWind（Tailwind CSS v3 の React Native 版） |
| サーバーデータ | TanStack Query（`useQuery` / `useMutation`） |
| 全体状態 | React Context（`AuthContext` / `FamilyContext`） |
| Push 通知 | expo-notifications（Edge Function の Expo 対応は未完 — 下記） |

## セットアップ

```bash
cd mobile
npm install
cp .env.example .env   # Supabase の URL / anon key を記入
npx expo start
```

- スマホ（iOS / Android）に **Expo Go** アプリを入れて、ターミナルの QR を読むと実機で動く
- Windows でも同じ手順で動く（iOS の実機ビルドだけは Mac か EAS Build が必要）

## `.env`

```
EXPO_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJ...
```

anon key はクライアント埋め込み前提の公開キー。**Service Role Key は絶対に置かない。**
`.env` は gitignore 済み。

## ディレクトリ

```
app/                    ルーティング（expo-router）
  _layout.tsx           プロバイダ + 認証/家族状態による画面ゲート
  login.tsx / signup.tsx
  family-gate.tsx       家族未参加時
  family/create|join|members
  (tabs)/               ホーム / 履歴 / 設定
  button/new|[id]       報告ボタンの作成・編集
  settings/display-name|family-name
src/
  lib/                  supabase クライアント、JST カレンダー、アイコン定数
  services/             Supabase 呼び出し（Swift 版 Services/ と 1:1）
  context/              AuthContext / FamilyContext
  hooks/                useHome（報告ボタン + DAILY 判定 + 報告 mutation）
  components/            画面共通 UI（UI をいじるのは主にここ）
  types/models.ts       DB テーブルの型
```

## UI / UX を改善したい人向け

- 色・角丸は `tailwind.config.js` の `theme.extend`（`brand` 色、`rounded-card/field/cell`）
- ボタンの見た目は `src/components/ui/Button.tsx` 一箇所
- 各画面のレイアウトは `app/**` の該当ファイル
- 変更は Expo Go で即ホットリロードされる

## 未完タスク（移行の残り）

- [x] Realtime（`reports` 変更購読 → ホーム/履歴の自動更新）。`src/services/realtime.ts` +
  `useFamilyReportsRealtime`。※実機での配信体感確認は未
- [ ] Push 通知: `supabase/functions/send-family-notification` を APNs 直叩きから **Expo Push API** 経由に書き換え。`src/services/push.ts` の `registerForPushNotifications` は実装済み（`device_tokens` に `platform='expo'` で保存）。`RootLayout` からの許可リクエスト呼び出しも未接続
- [ ] 通知設定画面（システム許可状態の表示 + 設定アプリ導線）
- [ ] SwiftUI 版（`../FamilyTap/`）の削除（Expo 版の実機確認が済んでから）
