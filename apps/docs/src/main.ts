import { Api } from "@bida/api-contract";
import { OpenApi } from "effect/http-api";
import SwaggerUI from "swagger-ui-dist/swagger-ui-es-bundle.js";
import "swagger-ui-dist/swagger-ui.css";

// "Try it out" sends requests here; set VITE_API_URL when building for a host.
const apiUrl = import.meta.env.VITE_API_URL ?? "http://localhost:3000";

SwaggerUI({
  dom_id: "#swagger-ui",
  spec: { ...(OpenApi.fromApi(Api) as object), servers: [{ url: apiUrl }] },
});
