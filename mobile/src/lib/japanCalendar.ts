/**
 * DAILY 判定ヘルパー（Swift 版 JapanCalendar と 1:1、仕様書 31/32）。
 * DB は UTC 保存だが、DAILY ボタンの「今日」は常に Asia/Tokyo のカレンダー日。
 *
 * JST は UTC+9 で固定オフセット（夏時間なし）なので、UTC ミリ秒に 9h 足して
 * 「その瞬間の JST の年月日時分」を取り出す、という単純計算で扱える。
 */

const JST_OFFSET_MS = 9 * 60 * 60 * 1000;

/** その瞬間を JST に直したときの Date（getUTC* すると JST の値が読める擬似 Date）。 */
function toJstParts(d: Date): Date {
  return new Date(d.getTime() + JST_OFFSET_MS);
}

/** [今日 00:00, 明日 00:00)（JST）を、UTC の絶対時刻（ISO 文字列）で返す。 */
export function todayRange(now: Date = new Date()): { start: string; end: string } {
  const jst = toJstParts(now);
  const startJstMs =
    Date.UTC(jst.getUTCFullYear(), jst.getUTCMonth(), jst.getUTCDate()) - JST_OFFSET_MS;
  return {
    start: new Date(startJstMs).toISOString(),
    end: new Date(startJstMs + 24 * 60 * 60 * 1000).toISOString(),
  };
}

/** "07:12"（JST）。DAILY ボタンの報告時刻表示用。 */
export function timeString(iso: string): string {
  const jst = toJstParts(new Date(iso));
  const hh = String(jst.getUTCHours()).padStart(2, '0');
  const mm = String(jst.getUTCMinutes()).padStart(2, '0');
  return `${hh}:${mm}`;
}

/** "今日" / "昨日" / "8月5日"（JST カレンダー日基準）。履歴のグルーピング用。 */
export function dayLabel(iso: string, now: Date = new Date()): string {
  const entry = toJstParts(new Date(iso));
  const today = toJstParts(now);
  const startEntry = Date.UTC(
    entry.getUTCFullYear(),
    entry.getUTCMonth(),
    entry.getUTCDate(),
  );
  const startToday = Date.UTC(
    today.getUTCFullYear(),
    today.getUTCMonth(),
    today.getUTCDate(),
  );
  const daysAgo = Math.round((startToday - startEntry) / (24 * 60 * 60 * 1000));
  if (daysAgo <= 0) return '今日';
  if (daysAgo === 1) return '昨日';
  return `${entry.getUTCMonth() + 1}月${entry.getUTCDate()}日`;
}
