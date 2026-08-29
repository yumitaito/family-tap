/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './src/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      // Swift 版のデザイン言語を踏襲:
      // カード=16 / 入力欄=12 / 小さいアイコンセル=10
      borderRadius: {
        card: '16px',
        field: '12px',
        cell: '10px',
      },
      colors: {
        // アクセント（Swift の AccentColor 相当）。friend が触るならここ1箇所。
        brand: {
          DEFAULT: '#0A84FF',
          fg: '#FFFFFF',
        },
      },
    },
  },
  plugins: [],
};
