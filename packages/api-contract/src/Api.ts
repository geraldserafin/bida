import { HttpApi, OpenApi } from "effect/http-api";
import { AuthApi } from "./auth/index.ts";
import { SystemApi } from "./system/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(AuthApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      description:
        "Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Amounts are integers in grosze (12.34 PLN is 1234).",
      version: "0.0.0",
    }),
  ) {}
