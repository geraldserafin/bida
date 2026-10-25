import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Repository tests run against a real Postgres, so keep them off the dev db
    env: {
      DATABASE_URL:
        process.env.TEST_DATABASE_URL ??
        "postgres://bida@127.0.0.1:5432/bida_test",
    },
    // Test files share one database
    fileParallelism: false,
  },
});
