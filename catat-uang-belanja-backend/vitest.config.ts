import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    env: {
      JWT_SECRET: 'test-secret-do-not-use-in-prod',
      GOOGLE_CLIENT_ID: 'test-google-client-id',
      DATABASE_URL: 'postgresql://test:test@localhost:5432/test',
    },
  },
});
