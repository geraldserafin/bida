import { writeFileSync } from "node:fs";
import { OpenApi } from "effect/http-api";
import { Api } from "../src/index.ts";

const output = new URL("../openapi.json", import.meta.url);
writeFileSync(output, `${JSON.stringify(OpenApi.fromApi(Api), null, 2)}\n`);
console.log(`wrote ${output.pathname}`);
