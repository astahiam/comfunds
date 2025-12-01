const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */
const config = {
  watchFolders: [],
  resolver: {
    blockList: [
      /node_modules\/.*\/node_modules\/react-native\/.*/,
      /android\/.*/,
      /ios\/build\/.*/,
      /\.git\/.*/,
    ],
  },
  watcher: {
    healthCheck: {
      enabled: true,
    },
    watchman: {
      deferStates: ['hg.update'],
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
