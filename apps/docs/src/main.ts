import { Api } from "@bida/api-contract";
import { OpenApi } from "effect/http-api";
import SwaggerUI from "swagger-ui-dist/swagger-ui-es-bundle.js";
import "swagger-ui-dist/swagger-ui.css";

SwaggerUI({
  dom_id: "#swagger-ui",
  spec: OpenApi.fromApi(Api) as object,
});
