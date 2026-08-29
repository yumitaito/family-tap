module.exports = function (api) {
  api.cache(true);
  return {
    presets: [
      ['babel-preset-expo', { jsxImportSource: 'nativewind' }],
      'nativewind/babel',
    ],
    // react-native-worklets/plugin は必ず最後に置く（Reanimated 4 の要件）
    plugins: ['react-native-worklets/plugin'],
  };
};
