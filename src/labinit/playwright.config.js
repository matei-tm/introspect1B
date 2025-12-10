module.exports = {
  timeout: 60000,
  testDir: 'tests',
  use: {
    headless: true,
    viewport: { width: 1280, height: 720 },
    actionTimeout: 0,
    video: 'retain-on-failure',
    screenshot: 'only-on-failure'
  }
};
