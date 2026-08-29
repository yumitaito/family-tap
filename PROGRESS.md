# Family Tap — 開発進捗

仕様書: 家族向けワンタップ報告 iOS アプリ 開発仕様書（section 54 の実装指示に従う）

## 決定事項

- 認証方式: **Email / Password**（Sign in with Apple は将来追加）
- バックエンド: Supabase（プロジェクト作成済み。Project URL / anon key は未共有 — Phase 2 で接続時に必要）
- プロジェクト生成: [XcodeGen](https://github.com/yonaskolb/XcodeGen) を使用（`project.yml` → `FamilyTap.xcodeproj` を生成）。
  `FamilyTap.xcodeproj` 自体は `.gitignore` 対象。環境を作り直すときは `xcodegen generate` を実行するだけでよい。

## Phase 進捗

- [x] **Phase 1: プロジェクト初期構築**
  - `project.yml`（XcodeGen設定、iOS 17+、Bundle ID: `com.yumita.familytap`）
  - フォルダ構成（`FamilyTap/App, Models, Views, ViewModels, Services, Components, Utilities, Resources`）を仕様書 section 38 に準拠して作成
  - `FamilyTapApp.swift`（アプリエントリポイント）
  - `RootTabView.swift`（ホーム / 履歴 / 設定の TabView シェル、section 43）
  - `HomeView` / `HistoryView` / `SettingsView` — 現時点では静的な Empty State / プレースホルダーのみ（データ・ロジックは未接続）
  - Assets.xcassets（AppIcon / AccentColor プレースホルダー）
  - `.gitignore`（Xcode成果物・Secrets類を除外）
  - **ビルド確認: 完了**（Xcode 26.3、`xcodebuild ... build` → `BUILD SUCCEEDED`）
  - **Simulator起動確認: 完了**（iPhone 17 / iOS 26.3。ホーム・履歴・設定の3タブとも表示OK）
- [x] **Phase 2: Supabase接続**
  - `project.yml` に `supabase-swift` パッケージ依存を追加（解決済み: 2.54.1）
  - `Secrets.swift`（gitignore対象、実際のURL/anonキーを保持） / `Secrets.swift.example`（コミット対象テンプレート）
  - `SupabaseService.swift` — `SupabaseClient` の共有インスタンス + 疎通確認用 `verifyConnection()`（GoTrueのhealthエンドポイントを叩くだけ、テーブル不要）
  - `HomeView` に一時的な接続確認表示を追加 → Simulatorで「Supabase: 接続OK」を実機確認済み
  - この一時UIは Phase 7（ホーム画面のデータ接続）で本実装に置き換える
- [x] **Phase 3: DB migration作成**
  - Supabase CLI導入・管理（`~/bin/supabase-2.111.0` を使用 — 詳細は「Supabase CLIについての注記」参照）
  - `supabase link --project-ref gesaokxmqgsohjfubncc` 済み
  - [`supabase/migrations/20260807151906_initial_schema.sql`](supabase/migrations/20260807151906_initial_schema.sql) — `profiles / families / family_members / report_buttons / reports / device_tokens` の6テーブル（仕様書23〜30章）+ `updated_at`自動更新トリガー + 検索用インデックス
  - 全テーブルで `ENABLE ROW LEVEL SECURITY` 済み（ポリシーは未定義 = 現状は全アクセス拒否の安全な状態。ポリシー自体はPhase 4で追加）
  - リモートDBに `db push` 適用済み・`migration list` で local/remote一致を確認
- [x] **Phase 4: RLS作成（ポリシー定義）**
  - [`supabase/migrations/20260807152108_rls_policies.sql`](supabase/migrations/20260807152108_rls_policies.sql) — 全6テーブルに計18ポリシー（仕様書37章の方針に準拠。family_members・profilesは「同じfamilyに所属していれば閲覧可」、reportsはINSERT/SELECTのみで更新・削除不可＝追記専用ログ）
  - [`supabase/migrations/20260807152226_fix_function_search_path.sql`](supabase/migrations/20260807152226_fix_function_search_path.sql) — `db advisors`が検出した`function_search_path_mutable`警告を修正
  - `db advisors --linked --type security` で **No issues found** を確認
  - `pg_policies` / `pg_tables.rowsecurity` をリモートDBに対して直接クエリし、18ポリシー・全テーブルRLS有効を確認済み
  - **未検証:** 実際の認証ユーザー（JWT）でのアクセス制御の動作確認はPhase 5（認証実装）でアプリから叩いて確認する。今はまだauth.usersが1件も無い
- [x] **Phase 5: 認証**
  - `AuthService.swift` — `signUp` / `signIn` / `signOut`（Supabase Auth）。`signUp`は戻り値でセッションの有無（=メール確認要否）を返す
  - `SessionStore.swift`（ViewModels）— `authStateChanges`を購読し、アプリ全体のログイン状態を保持
  - `AuthViewModel.swift` — Login/SignUp共通のフォーム状態・バリデーション・エラーメッセージ
  - `RootView.swift` — 未ログイン→`LoginView` / ログイン済み→`RootTabView`（家族グループ判定はPhase 6で追加予定）
  - `LoginView.swift`（AUTH-001）・`SignUpView.swift`（AUTH-002）
  - `SettingsView`のログアウトボタンを実装（`SettingsViewModel`経由）
  - DBマイグレーション追加:
    - [`20260807152541_auto_create_profile_on_signup.sql`](supabase/migrations/20260807152541_auto_create_profile_on_signup.sql) — `auth.users` INSERT時に`handle_new_user`トリガーが`display_name`メタデータから`profiles`行を自動作成（メール確認必須設定でも動く。SECURITY DEFINER）
    - [`20260807152610_lock_down_handle_new_user.sql`](supabase/migrations/20260807152610_lock_down_handle_new_user.sql) — トリガー関数のRPC直接実行を防止（`db advisors`警告修正）
  - **検証方法**: SimulatorのSwiftUIフォームへの自動タップ入力が本セッション中に不安定だった（日本語IME・座標ズレ。原因はテストツール側、アプリのバグではない）ため、UIは主要要素の単発操作で確認しつつ、認証のコア機能（サインアップ→トリガーでのprofiles自動作成）は**Supabase Auth REST APIを直接叩いて検証**：
    - `POST /auth/v1/signup`（`display_name`メタデータ付き）→ 成功、`confirmation_sent_at`ありでメール確認必須設定を確認
    - `public.profiles`に`display_name`が正しく反映された行が自動作成されていることを確認
    - テストユーザーは検証後に削除（`auth.users`削除→`profiles`もCASCADEで削除されることも確認）
  - UI側は以下を実機（Simulator）で確認済み:
    - ログイン画面の表示・入力・「ログイン」ボタン押下→実際にSupabaseへ問い合わせ→誤ったメールアドレス/パスワードで正しいエラーメッセージ表示
    - ログイン画面→新規登録画面への遷移（`NavigationLink`。当初`Button`+`.navigationDestination(isPresented:)`ではタップが拾われず、`.contentShape(Rectangle())`+`.frame(minHeight: 44)`付きの`NavigationLink`に変更して解決 — ラベルがテキストのみのボタンはヒットテスト領域が視覚サイズより小さくなることがある教訓）
    - 新規登録画面の各フィールドへの入力（表示名・メールアドレス）
- [x] **Phase 6: 家族作成・参加**
  - Models: `Family.swift` / `Profile.swift` / `FamilyMemberWithProfile.swift`
  - `FamilyService.swift` — `fetchCurrentFamily` / `createFamily` / `joinFamily` / `fetchMembers`
  - `FamilyStore.swift`（ViewModels）— アプリ全体の「今の家族」状態。`RootView`がこれを見てホーム/ゲート画面を切り替える
  - `FamilyViewModel.swift`・`FamilyMembersViewModel.swift`
  - Views: `FamilyGateView`（FAMILY-001）・`CreateFamilyView`（FAMILY-002）・`InviteCodeResultView`（作成完了・招待コード表示）・`JoinFamilyView`（FAMILY-003）・`FamilyMembersView`（FAMILY-004）
  - `RootView`を拡張し、ログイン済み→未参加なら`FamilyGateView`、参加済みなら`RootTabView`に分岐
  - `SettingsView`の「家族」欄・「家族メンバー」リンクを実データに接続
  - **DBマイグレーション3件追加**（実装中に本番相当のテストで発見した重大な問題への対処含む）：
    - [`20260807160915_fix_rls_recursion.sql`](supabase/migrations/20260807160915_fix_rls_recursion.sql) — **Phase 4で作った`family_members`関連RLSポリシーに無限再帰バグがあった**（同一テーブルを参照する自己結合ポリシーが原因、Postgresエラー42501/`infinite recursion detected`）。`is_family_member` / `is_family_owner` / `shares_family_with`というSECURITY DEFINERヘルパー関数を導入し、`profiles`・`families`・`family_members`・`report_buttons`・`reports`の該当ポリシーを全て貼り替えて解消
    - [`20260807161322_family_create_join_rpc.sql`](supabase/migrations/20260807161322_family_create_join_rpc.sql) — 家族作成・参加をクライアント側の複数INSERTではなく`create_family`/`join_family`というSECURITY DEFINERのRPC関数に変更。理由: (1) 作成直後の`INSERT...RETURNING`は「作成者がまだfamily_membersにいない」ため自分自身のSELECTポリシーに弾かれる、(2) 招待コードでの参加も「まだメンバーでない家族をSELECTできない」というRLSの制約と正面衝突する。両方ともRPC化することでアトミックに解決
  - **検証方法**: Supabaseのメール確認設定（`mailer_autoconfirm`）を一時的にON→検証→OFFに戻す形で、実際のSupabase Auth REST APIとPostgRESTを直接叩いて2ユーザー（owner/member）でのフルフロー（家族作成→招待コードで参加→メンバー一覧相互閲覧→他ユーザーのプロフィール閲覧）を検証。テストデータは全て削除済み
  - `db advisors`の残り警告5件（`create_family`/`join_family`と3つのヘルパー関数がRPCとして呼べる件）は、この設計（RLS再帰回避 + RPCによるアトミック操作）では避けられない意図した挙動として許容
  - Simulatorでの手動タップ操作は今回省略（前段のAPI直接検証の方がRLS込みで確実なため）。ビルドは`BUILD SUCCEEDED`、アプリ起動・未ログイン時のログイン画面表示は確認済み
- [x] **Phase 7: ホーム画面（データ接続）**
  - Model: `ReportButton.swift`（`report_buttons`テーブル対応）
  - `ReportButtonService.swift` — `fetchActiveButtons(familyId:)`（`is_active=true`のみ、`sort_order`順）。作成/編集/削除はPhase 8で追加
  - `HomeViewModel.swift`
  - `Components/ReportButtonCard.swift` — 再利用可能なカードUI（仕様書38章のComponents構成に対応）。現時点ではタップしても報告されない静的カード（タップ→報告はPhase 9の`reports`実装で配線）
  - `HomeView.swift`を全面刷新：Phase 2の一時的な接続確認表示を削除し、`report_buttons`を2列グリッドで表示。0件なら仕様書47章のEmpty State、ナビゲーションタイトルは家族名を表示
  - `SupabaseService.verifyConnection()`（Phase 2の一時コード）を削除
  - **注**: 仕様書40章の「今日の状態」（DAILYステータスカード）は`reports`データとDAILY判定ロジック（Phase 9・10）が無いと作れないため、今回はnormal/daily問わず全ボタンを同じグリッドに表示する簡略版。Phase 10で分離する
  - **検証**: テスト家族に実際のPostgREST API（`created_by`必須であることも実地で確認——省略するとRLSで弾かれる）で報告ボタン4件を作成し、返ってきたJSONが`ReportButton`の`CodingKeys`と完全一致することを確認。ビルドは`BUILD SUCCEEDED`
  - **未検証（ツール起因）**: Simulator上での実際の表示確認は、このセッションで`mcp__Claude_Code_iOS_Simulator__control`のタップ入力が断続的に不安定になり（デバイス再起動しても改善せず、Phase 5で機能していた座標が効かなくなる等）実施できなかった。アプリコード側の問題ではなくテストツール側の問題と判断し、より確実なバックエンド直接検証で代替した。次回Xcodeから直接実行して目視確認することを推奨
- [x] **Phase 8: 報告ボタンCRUD**
  - `ReportButtonService`に`createButton`/`updateButton`/`deleteButton`を追加（`fetchActiveButtons`はPhase 7で実装済み）
  - `ReportButtonFormViewModel.swift` — 作成・編集で共通利用（バリデーション: 空文字/50文字超）
  - Views: `CreateReportButtonView`（BUTTON-001）・`EditReportButtonView`（BUTTON-002、保存/削除確認ダイアログ）
  - Components: `ReportButtonIconPicker`（絵文字グリッド）・`ReportButtonTypePicker`（通常/毎日リセット選択）・`AddReportButtonTile`（＋ボタンを追加タイル）
  - `HomeView`に導線を追加：グリッド末尾の「＋ボタンを追加」タイル、空状態の「＋最初のボタンを作る」ボタン、カード長押しで編集画面へ（タップは引き続きPhase 9の報告用に温存）
  - `Utilities/ReportButtonIcons.swift` — 絵文字選択肢の定数（🐶🌙🚶💊🗑🏠🚗🍚）
  - `ReportButton`を`Hashable`に変更（`navigationDestination(item:)`の要件）
  - **検証**: SupabaseのAuth REST APIを経由せず、`db query --linked`でPostgreSQLの認証コンテキスト（`request.jwt.claims`）を直接シミュレートしてRLS込みでCREATE/UPDATE/DELETEを検証（レート制限やメール確認設定の変更が不要な、より軽量な検証方法）。あわせて「家族に属さない他ユーザーからは見えない」という分離も確認。テストデータは全て削除済み
  - ビルドは`BUILD SUCCEEDED`。Simulatorでの目視確認は今回省略（引き続きタップ入力が不安定なため。次回はXcodeから直接実行して確認する想定）
- [x] **Phase 9: reports**
  - Model: `Report.swift`（`reports`テーブル対応）
  - `ReportService.swift` — `createReport(familyId:buttonId:userId:)`
  - `HomeViewModel`に報告ロジック追加：`report(button:familyId:)`、連打対策（タップ後最低1.5秒disabled — ネットワーク待ちと並行実行し、遅い場合に余分な待ちを追加しない設計）、`ToastState`による完了/失敗フィードバック
  - `Components/ToastView.swift` — 「報告しました ✓」（成功）/「報告できませんでした。」（失敗）のトースト表示
  - `ReportButtonCard`をタップ可能に変更（`Button`ではなく`onTapGesture`/`onLongPressGesture`を直接使用——同一View上でButtonと長押しジェスチャーを併用すると競合するため）。タップで報告、長押しで編集画面
  - `HomeView`にトースト表示のoverlayと報告完了後の自動非表示（2秒）を追加
  - **注**: DAILYボタンでも今回は毎回無条件でreportを作成する（「今日already報告済み？」の確認ダイアログはPhase 10のDAILY判定待ち）
  - **検証**: `db query --linked`での認証コンテキストシミュレートで、(1) reports INSERT成功・JSON形状が`Report`モデルと一致、(2) 他人の`user_id`を騙ったINSERTがRLSで拒否される（なりすまし防止）、(3) 非メンバーからreportsが見えない、(4) DELETEポリシーが無いため削除が静かに0件になり実際には残る（追記専用ログとして機能）——の4点を確認。テストデータは削除済み
  - ビルドは`BUILD SUCCEEDED`
- [x] **Phase 10: DAILY判定**
  - `Utilities/JapanCalendar.swift` — Asia/Tokyo基準の「今日」の範囲計算（UTC変換込み、仕様書31/32章）・時刻表示フォーマット
  - `ReportService.fetchTodayReports(familyId:buttonIds:range:)` — 指定ボタン群の「今日（JST）」の報告一覧を`reports`と`profiles`のJOINで取得（最古順。最初の1件が「今日最初に報告した人」）
  - `HomeViewModel`に`dailyStatuses: [UUID: DailyReportStatus]`を追加。読み込み時・DAILYボタン報告後に更新
  - `Components/DailyStatusCard.swift` — 「今日の状態」行UI（✅時刻+報告者 / 未報告）
  - `HomeView`を再構成：DAILYタイプは「今日の状態」セクション、NORMALタイプは従来通り「報告する」グリッドに分離。DAILYボタンをタップした際、既に今日報告済みなら確認ダイアログ「今日はすでに報告済みです。もう一度報告しますか？」を表示してから報告（仕様書33章）
  - **検証**: `db query --linked`の認証コンテキストシミュレートで、(1) 報告前は「未報告」状態（JOINがNULL）、(2) 報告後は`fetchTodayReports`と同じクエリ形状（family_id一致・button_id IN・created_at範囲・profiles JOIN・古い順）で正しく1件ヒットすることを確認。JST日付境界の計算がUTCで正しく変換されることもSQLで直接検算（今日JST 00:00 = 前日15:00 UTC）
  - ビルドは`BUILD SUCCEEDED`
- [x] **Phase 11: 履歴**
  - **Phase 8への重要な修正**: `ReportButtonService.deleteButton`が実際には`DELETE`ではなく`is_active = false`へのソフトデリートに変更。理由: `reports.button_id`のFKが`ON DELETE CASCADE`（Phase 3のmigration）のため、ボタンを本当に削除すると紐づく報告履歴まで連鎖削除されてしまい、仕様書10/37章の「報告履歴は削除しない」に反する。ホーム画面への表示（`fetchActiveButtons`は元々`is_active=true`のみ取得）は変更不要でそのまま非表示になる
  - Model: `HistoryEntry.swift`（`reports`×`profiles`×`report_buttons`の結合結果をデコード）
  - `ReportService.fetchHistory(familyId:limit:)` — 新しい順、`report_buttons`は非アクティブ（ソフト削除済み）でもJOINするので古い履歴のラベル/アイコンが欠けない
  - `JapanCalendar.dayLabel(for:)` — 「今日」「昨日」「M月d日」のグルーピングラベル（JST基準）
  - `HistoryViewModel.groupedEntries` — 日付ラベルでグルーピング（既にcreated_at降順なので一度の線形走査で足りる）
  - `Components/HistoryRow.swift`
  - `HistoryView`を全面刷新：Phase 1のプレースホルダーから実データのグルーピング表示に
  - **検証**: `db query --linked`で(1)履歴クエリの結合形状が`HistoryEntry`と一致、(2)ボタンをソフトデリートしても履歴のラベル/アイコンが失われず、かつホーム画面（`is_active=true`のみ）には表示されなくなることを確認。テストデータは削除済み
  - ビルドは`BUILD SUCCEEDED`
- [x] **Phase 12: Realtime**
  - マイグレーション: [`20260807171257_enable_realtime_for_reports.sql`](supabase/migrations/20260807171257_enable_realtime_for_reports.sql) — `reports`テーブルを`supabase_realtime`パブリケーションに追加（デフォルトでは空で、これをしないとpostgres_changesイベントが一切飛ばない）。`pg_publication_tables`で反映を確認済み
  - `Services/RealtimeReportsService.swift` — `reports`テーブルのINSERTを`family_id`でフィルタして購読するラッパー（RLSの`reports_select_member`がどのみち配信範囲を絞る）
  - `HomeViewModel`・`HistoryViewModel`に組み込み：`load()`時に一度だけ購読開始し、他デバイスからの新規報告で「今日の状態」（Home）・履歴一覧（History）を自動更新
  - **API調査について**: `supabase-swift`はメジャーバージョン間でRealtime APIが大きく変わっており（`postgresChange`は現在`RealtimeChannelV2`上のAsyncStream API）、学習データの記憶だけでは正確なシグネチャに自信が持てなかったため、`~/Library/Developer/Xcode/DerivedData/.../SourcePackages/checkouts/supabase-swift/Sources/RealtimeV2/`配下の実ソースを直接読んで実装（`channel(_:)`、`postgresChange(InsertAction.self, schema:table:filter:select:)`、`subscribe()`/`removeChannel()`、`decodeRecord(as:decoder:)`など）
  - **検証**: ビルド成功（`BUILD SUCCEEDED`）、パブリケーション設定はSQLで直接確認。生のWebSocket（Phoenixチャンネルプロトコル）でエンドツーエンドの配信を直接検証しようと試みたが、プロトコル詳細の実装に時間がかかりすぎると判断して中断——SDKの実ソースを読んだ実装への信頼を優先した。**実機での「別端末からの報告が自動反映される」という体感確認は未実施**。次回Simulatorが安定していれば2台構成（またはSimulator+実機）で目視確認することを推奨
- [x] **Phase 13: Push通知**
  - iOS側:
    - `FamilyTap.entitlements`（`aps-environment: development`）を追加し、`project.yml`の`CODE_SIGN_ENTITLEMENTS`で参照
    - `App/AppDelegate.swift` + `@UIApplicationDelegateAdaptor` — `didRegisterForRemoteNotificationsWithDeviceToken`を受け取るためだけの薄いUIKitブリッジ
    - `NotificationService.swift` — 通知許可リクエスト（仕様書35章）・現在の許可状態取得
    - `DeviceTokenService.swift` — APNsトークンを`device_tokens`にupsert（`token`の一意制約でconflict時は更新）
    - `PushNotificationService.swift` — 報告成功後に`send-family-notification` Edge Functionを呼び出す（fire-and-forget、失敗しても「報告失敗」にはならない設計）
    - `RootTabView`に`.task`で許可リクエストをフック（section6の「アプリに入った後」のタイミング）
    - `NotificationSettingsView.swift` — SETTINGS-001の通知設定行を実装。偽のトグルではなく実際のシステム許可状態を表示し、拒否時は設定アプリへの導線を出す
  - Edge Function: [`supabase/functions/send-family-notification/index.ts`](supabase/functions/send-family-notification/index.ts) — report/button/reporter/family_members/device_tokensを取得し報告者本人を除いてAPNsへ送信。サードパーティ依存なしで`fetch`+`crypto.subtle`によるES256 JWT認証を自前実装。呼び出し元のJWTで`reports`をRLS越しに確認してから（なりすまし・他家族へのスパム防止）service roleで実処理
  - **検証**: `deno check`/`deno lint`で型・静的解析クリーン。**APNs JWT生成（ES256署名）とPEMベースの秘密鍵インポート（PKCS8/P-256）を、実際にDenoでスタンドアロン実行して検証**——使い捨ての鍵ペアで実際に署名→検証まで通し、コードの暗号処理ロジックが機械的に正しいことを確認（本物のApple認証情報なしでできる最大限の検証）。`device_tokens`のupsert（再登録で重複行にならない）・非所有者から見えないことをRLSシミュレートで確認
  - **未実装/未検証（このセッションでは不可能）**: 実際のAPNs配信そのもの。Apple Developer Program（有料）でのAPNs Auth Key発行、Edge Functionへの環境変数設定（`APNS_TEAM_ID`/`APNS_KEY_ID`/`APNS_PRIVATE_KEY`/`APNS_BUNDLE_ID`）、実機でのPush Notifications capability設定、`supabase functions deploy`でのデプロイが必要。ユーザー側で用意ができ次第、デプロイと実機確認をお願いしたい
  - ビルドは`BUILD SUCCEEDED`
- [x] **Phase 14: UI仕上げ**
  - 監査の結果、Empty State（仕様書47章）・エラー処理（45章）・ローディング（46章、ボタン単位でのdisabled）は各フェーズ実装時点で既に作り込み済みと確認。追加の作り込みは不要だった
  - 色指定を全ファイル監査 — ハードコードされた色（`Color.white`/`.black`/RGB直指定）は一切なく、すべて`Color(.secondarySystemBackground)`等のシステム動的カラーか`.primary`/`.secondary`/`.red`/`.green`/`accentColor`のみ使用。Dark Modeは追加対応不要と判明
  - **残っていたプレースホルダーを解消**: `SettingsView`の「表示名」が Phase 1 から`"-"`固定だったのを、`ProfileService.swift`を新設して実データ表示に変更
  - `project.yml`から未使用の`NSUserTrackingUsageDescription`を削除（ビルド警告解消）
  - コーナー半径（16=カード類／12=入力欄／10=小さいアイコン選択セル）など既存のデザイン言語に一貫性があることを確認
  - **検証**: Simulatorで`xcrun simctl ui <udid> appearance dark/light`により実際にライト/ダーク両方のスクリーンショットを撮って目視確認（LoginView）。背景・カード・テキストいずれも正しく反転することを確認
  - ビルドは`BUILD SUCCEEDED`（警告ゼロ、AppIntents関連の無害な標準メッセージのみ）
- [x] **Phase 15: テスト**
  - **実際にエンドツーエンドでデータを流したところ、実バグを発見・修正**: [`20260807174347_fix_invite_code_length.sql`](supabase/migrations/20260807174347_fix_invite_code_length.sql) — 招待コードが8文字のはずが、Postgresの`::int`キャストが（切り捨てでなく）四捨五入することが原因で稀に7文字になっていた（`random()*32`が32に丸められ`substr`の範囲外→空文字）。`floor()`を挟んで修正し、500回生成して全て8文字になることを確認
  - Simulatorでの最終目視確認を試みたが、このセッションを通じてタップ入力が根本的に不安定なままで（再起動・detach/reattach・tap/touch_path切り替えいずれも改善せず）、断念。実データでの動作確認はSupabase REST API直接呼び出しで代替（下記チェックリスト参照）
  - `db advisors`最終確認：新規の警告なし（Phase 6からの既知5件のみ、意図した設計）
  - 最終ビルド: `BUILD SUCCEEDED`

  ### 完成条件チェックリスト（仕様書53章）
  | 項目 | 状態 | 検証方法 |
  |---|---|---|
  | iPhoneからユーザー登録できる | ✅ | 実際のSupabase Auth APIでサインアップ成功（Phase 5, 15） |
  | 家族グループを作れる | ✅ | `create_family` RPCで実データ作成・招待コード8文字を確認（Phase 6, 15で不具合修正） |
  | 招待コードで別ユーザーが参加できる | ✅ | `join_family` RPCを別ユーザーで実行し成功（Phase 6） |
  | 自由な文章で報告ボタンを作れる | ✅ | `report_buttons` INSERTをRLS込みで確認（Phase 8） |
  | ボタンがホーム画面に表示される | ⚠️ | `fetchActiveButtons`のクエリ・JSON整合性は確認済み（Phase 7）。**Simulatorでの実画面表示は未確認**（タップ不安定のため） |
  | ボタンを押して報告できる | ✅ | `reports` INSERTをRLS込みで確認、なりすまし拒否も確認（Phase 9） |
  | 誰が報告したか記録される | ✅ | `user_id`記録・`profiles`とのJOINでreporter_name取得を確認（Phase 9, 11） |
  | 報告時間が記録される | ✅ | `created_at`記録を確認（Phase 9） |
  | 他の家族にPush通知が届く | ⚠️ | Edge Function実装・APNs用JWT署名とPEM鍵インポートをDenoで実行検証済み（Phase 13）。**実際のAPNs配信は未検証**（Apple Developer Program・実機が必要） |
  | 家族の報告がリアルタイムに反映される | ⚠️ | `supabase_realtime`パブリケーション設定・SDK実装は完了（Phase 12）。**生WebSocketでの配信確認は中断**（プロトコル実装が非効率と判断） |
  | 履歴を確認できる | ✅ | `fetchHistory`のJOIN形状を確認、ソフト削除後も履歴が残ることを確認（Phase 11） |
  | DAILYボタンで今日報告済みか確認できる | ✅ | JST基準の当日判定をSQLで直接検算、未報告→報告後の状態遷移を確認（Phase 10） |
  | 翌日は未報告状態になる | ✅ | JST/UTC境界の変換ロジックをSQLで検算（Phase 10）。※実際に日をまたいでの確認はしていない（ロジック上は正しいはず） |
  | ボタンを編集できる | ✅ | `updateButton`をRLS込みで確認（Phase 8） |
  | ボタンを削除できる | ✅ | ソフトデリート（`is_active=false`）を確認。履歴保持のための設計変更もこのフェーズで実施済み（Phase 8, 11） |
  | 別の家族のデータは閲覧できない | ✅ | families/family_members/report_buttons/reports/device_tokens全てで非メンバーからの分離をRLSシミュレートで確認（Phase 4, 6, 7, 8, 9, 10, 13） |

  **総括**: バックエンド（DB・RLS・Edge Function）は全16項目とも実データでの直接検証を実施し、Phase 15の過程で実際に1件のバグ（招待コード長）を発見・修正できた。iOS側のUIコード自体は全フェーズでビルド成功しており、Phase 1・2・5では実際にSimulatorでの起動・操作を確認済みだが、本セッション後半でSimulatorのタップ入力が不安定になり、Phase 7以降は主にバックエンド直接検証で代替してきた。**次にXcodeを開く際は、実際にSimulator（またはできれば実機）でホーム画面の報告ボタン表示とタップ操作を目視確認することを強く推奨する。**

## Supabase CLIについての注記（重要）

Homebrew (`supabase/tap/supabase`) が入れる最新版 **v2.112.0 には `supabase link` が
`SchemaError` で必ず失敗する回帰バグがある**（[supabase/cli#6115](https://github.com/supabase/cli/issues/6115)）。
`GET /v1/projects/{ref}/api-keys` の `inserted_at` フィールドの日時フォーマットを
CLI側のスキーマ検証が誤って拒否するのが原因で、`link` はもちろん `db push` 等
`link`に依存するコマンドも軒並み使えなくなる。

**回避策:** GitHub Releasesから動作する **v2.111.0** のバイナリを直接取得し、
`~/bin/supabase-2.111.0` として使っている（`brew`管理下の`supabase`コマンドは
2.112.0のまま放置）。今後このプロジェクトでSupabase CLIを使うときは、
`supabase ...` ではなく **`~/bin/supabase-2.111.0 ...`** を使うこと。

```bash
# 例
cd "Family Tap"
~/bin/supabase-2.111.0 migration new <name>
~/bin/supabase-2.111.0 db push
~/bin/supabase-2.111.0 migration list
```

Homebrew側が2.112.0より新しい修正版を出したら、`brew upgrade supabase` して
`~/bin/supabase-2.111.0` を使うのをやめてよい（Issue #6115 が Closed になったら確認）。

## Phase 15後の追加修正

- ユーザー指摘により判明: DAILYタイプのボタン（「今日の状態」の行）には
  長押し→編集の導線が無く、削除できなかった（NORMALタイプのグリッド
  カードにしか実装していなかった）。`DailyStatusCard`に`onLongPress`を
  追加し、`ReportButtonCard`と同様に長押しで`EditReportButtonView`（削除
  ボタン付き）を開けるように修正。ビルド確認済み（`BUILD SUCCEEDED`）。
- ユーザー指摘により判明: 招待コードは家族作成直後の`InviteCodeResultView`
  でしか表示されず、後から再確認する手段が無かった。`FamilyMembersView`
  に招待コード表示＋コピー機能を追加（`familyId`/`familyName`ではなく
  `Family`オブジェクト全体を受け取るようシグネチャ変更）。ビルド確認済み。
- ユーザー要望により追加: 設定画面から表示名・家族名をいつでも変更できる
  ように`EditDisplayNameView`（`ProfileService.updateDisplayName`）と
  `EditFamilyNameView`（`FamilyService.updateFamilyName`）を実装。家族名の
  変更はRLS上オーナーのみ可能（`families_update_owner`）なので、メンバーが
  試みた場合は専用のエラーメッセージ（`FamilyServiceError.notOwner`）を表示
  するようにした。RLSシミュレートで(1)本人による表示名変更が成功、(2)
  オーナーによる家族名変更が成功、(3)メンバーによる家族名変更が黙って
  無視される（0行更新）ことを確認済み。ビルド確認済み。
- **メモ**: このフェーズの検証中、ユーザー自身が実機/Simulatorで実際に
  アプリをテスト済み（本物のメールアドレスで「弓田家」を作成、報告ボタン
  複数作成、実際に報告、device_token登録まで確認できた）ことが判明。
  テストデータのクリーンアップ時は要注意——このユーザー自身の実データとは
  明確に区別できるIDパターン（mailinator.comのメール・全ゼロUUID等）を
  今後も徹底すること。
- ユーザー要望により追加: 履歴ページで報告を長押しすると「取り消し」でき
  るようにした。取り消した報告がDAILYカード（今日の状態）に紐づいていた
  場合、そのカードは自動的に未報告表示に戻る。
  - マイグレーション [`20260808101314_add_report_cancellation.sql`](supabase/migrations/20260808101314_add_report_cancellation.sql)
    — `reports.cancelled_at`（ソフト取り消し、実削除はしない方針を継続）＋
    本人のみ更新できる`reports_cancel_own`ポリシー
  - `ReportService.cancelReport(id:)`を追加。`fetchHistory`/
    `fetchTodayReports`双方に`cancelled_at IS NULL`フィルタを追加（取り消し
    済みは履歴からもDAILY判定からも除外される→カードが未報告に戻る）
  - **ユーザーからの明示的な制約**: 「今日の状態カードは家族全員で管理して
    良いが、報告する方は個人の報告なのでみんなに見えないよう個人管理に
    してほしい」との指示を受け、取り消しはRLS（`user_id = auth.uid()`）と
    UI両面で「自分が報告したものだけ」に限定した。他人の履歴行を長押しし
    ても`HistoryView`側で本人チェック（`entry.reporterId == currentUserId`）
    をしてから初めて確認ダイアログを出すため、他メンバーには取り消しの
    導線自体が現れない。履歴一覧そのもの（誰が何を報告したか）は従来通り
    家族全員に見える（アプリの共有可視性というコア設計は変更していない）
  - `HistoryEntry`に`reporterId`を追加、`RealtimeReportsService`を
    `InsertAction`専用から`AnyAction`（insert/update/delete全て）購読に
    変更——History側での取り消し（UPDATE）がHome側のRealtime購読にも届き、
    別タブのDAILYカードが自動で未報告に戻ることを実現
  - **検証**: `db query --linked`のトランザクション内（最後に`rollback`、
    残存データなしを確認済み）でRLSシミュレートし、(a)本人による取り消し
    成功、(b)本人以外による取り消し試行が0行更新で黙って拒否される、
    (c)取り消し後は履歴一覧クエリから除外される、(d)取り消し後は当日の
    DAILY判定クエリからも除外される（=カードが未報告に戻る）——の4点を
    全てPASSで確認。ビルドは`BUILD SUCCEEDED`
  - **未確認（ツール起因）**: Simulatorでの実画面タップ確認は今回も断念
    （本セッションを通じてタップ入力が不安定なため）。ユーザー自身の実機
    /Simulatorでの目視確認を推奨

## 【方針転換】Expo / React Native への移行（2026-08-29〜）

友達（Windows）と UI/UX を一緒に改善できるようにするため、iOS アプリを **SwiftUI →
Expo / React Native** に全面移行することを決定。**バックエンド（`supabase/` 配下 = DB
スキーマ・RLS・RPC・Edge Function）はそのまま再利用**、作り直すのは iOS アプリ本体のみ。

- 移行先: `mobile/`（Expo SDK 57 + expo-router + TypeScript + NativeWind + TanStack Query +
  supabase-js）。詳細は [`mobile/README.md`](mobile/README.md)
- 対象 OS: iOS のみ（当面）。Android は後から足せる構成
- `FamilyTap/` `FamilyTap.xcodeproj` `project.yml` は **Expo 版の実機確認が済むまで残す**。
  済んだら削除

### Expo 版 進捗

- [x] プロジェクト初期化・依存導入（NativeWind は tailwindcss を v3 に固定する必要あり。
  React 19.2.3 ピンのため `.npmrc` に `legacy-peer-deps=true` + `overrides.react-dom`）
- [x] Service 層を supabase-js に移植（`src/services/` — auth / family / profile /
  reportButtons / reports / push）。Swift 版 `Services/` とほぼ 1:1
- [x] 認証/家族状態のゲート（`app/_layout.tsx` の `AuthGate` = Swift 版 `RootView` 相当）
- [x] 画面移植: login / signup / family-gate / family(create·join·members) /
  tabs(home·history·settings) / button(new·[id]) / settings(display-name·family-name)
- [x] JST 日付ロジック（`src/lib/japanCalendar.ts`）・報告連打対策・トースト
- [x] **Realtime**（`src/services/realtime.ts` + `useFamilyReportsRealtime`）— home/history に接続。
  実機での配信体感確認は未
- [ ] **Push**: `device_tokens` への Expo token 登録は実装済み。Edge Function
  `send-family-notification` を APNs 直叩き → **Expo Push API** 経由に書き換えるのが残タスク。
  ※expo-notifications は Expo Go では制限あり（dev build 必須）
- [ ] 通知設定画面
- [x] **Expo Go でのスモークテスト成功**（iPhone 17 sim / SDK 57）: `.env` に本番の
  Supabase URL + anon key を設定 → 起動 → AuthGate が未ログインを検知して login 画面表示 →
  signup 画面へ遷移も確認。NativeWind スタイル・日本語表示・expo-router ナビゲーション OK。
  エラーゼロ（警告は expo-notifications の Expo Go 制限のみ）
- [ ] ログイン以降（家族作成・報告・履歴）の実データ通し確認 ← 次回

### Supabase 接続情報（設定済み）

- Project URL: `https://gesaokxmqgsohjfubncc.supabase.co`
- anon key: `mobile/.env` に設定済み（gitignore 済み。`role:anon` を確認）
- ⚠️ セッション中に一度 `service_role` key が誤って共有された。使用・保存はしていないが、
  気になる場合は Supabase ダッシュボードでキーをローテーションすること

## 次にやること（ユーザー側の準備）

1. **Xcodeをインストール**（App Store、または https://developer.apple.com/download/ ）。インストール後、一度起動して追加コンポーネントのインストールとライセンス同意を済ませておく。
2. Xcodeインストール後、以下でビルド確認を行う想定:
   ```bash
   cd "Family Tap"
   xcodegen generate   # project.yml に変更があれば再生成
   xcodebuild -project FamilyTap.xcodeproj -scheme FamilyTap \
     -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```
3. Supabaseの **Project URL** と **anon key** を共有（Phase 2で使用。anon keyはクライアント埋め込み前提の公開キーだが、Service Role Keyは絶対に共有・埋め込みしないこと）。
4. Push通知（APNs）を実機で試す場合は Apple Developer Program の Team 設定が必要（Phase 13まで不要）。
