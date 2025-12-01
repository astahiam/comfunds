/**
 * App Configuration
 */

export const Config = {
  API_BASE_URL: __DEV__
    ? 'http://localhost:8080/api/v1'
    : 'https://api.hajifund.com/api/v1',
  FRONTEND_URL: __DEV__
    ? 'http://localhost:3000'
    : 'https://hajifund.com',
  APP_NAME: 'Hajifund',
  APP_DESCRIPTION: 'Solusi Terbaik Crowdfunding Berbasis Syariah',
  VERSION: '1.0.0',
};

export default Config;

