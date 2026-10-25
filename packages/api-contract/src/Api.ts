import { HttpApi, OpenApi } from "effect/http-api";
import { SystemApi } from "./system/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      version: "0.0.0",
    }),
  ) {}
