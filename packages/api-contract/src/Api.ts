import { HttpApi, OpenApi } from "effect/http-api";
import { AuthApi } from "./auth/index.ts";
import {
  AccountApi,
  EnvelopesApi,
  ExpensesApi,
  HouseholdsApi,
  MembersApi,
  RecurringApi,
  SyncApi,
  WalletApi,
} from "./money/index.ts";
import { SystemApi } from "./system/index.ts";

export class Api extends HttpApi.make("bida")
  .add(SystemApi)
  .add(AuthApi)
  .add(AccountApi)
  .add(SyncApi)
  .add(WalletApi)
  .add(HouseholdsApi)
  .add(MembersApi)
  .add(EnvelopesApi)
  .add(ExpensesApi)
  .add(RecurringApi)
  .annotateMerge(
    OpenApi.annotations({
      title: "Money Planner API",
      description:
        "Everything except `/health` and `/auth` needs a signed-in user: send the session token as `Authorization: Bearer`, or let the browser send the session cookie. Amounts are integers in grosze (12.34 PLN is 1234). Call `POST /sync` when the app starts: nothing happens on the server in the background.",
      version: "0.5.0",
    }),
  ) {}
