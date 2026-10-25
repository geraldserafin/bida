import { Api, CurrentMember, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { ContributionsService } from "./contributions.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const ContributionsHttp = HttpApiBuilder.group(
  Api,
  "contributions",
  Effect.fn(function* (handlers) {
    const contributions = yield* ContributionsService;
    return handlers
      .handle("list", ({ params }) => contributions.listForPeriod(params.id))
      .handle("add", ({ params, payload }) =>
        Effect.flatMap(CurrentUser, ({ user }) =>
          contributions.add(params.id, payload, user.id),
        ),
      )
      .handle("delete", ({ params }) =>
        Effect.gen(function* () {
          const { user } = yield* CurrentUser;
          const { role } = yield* CurrentMember;
          yield* contributions.remove(params.id, user.id, role);
        }),
      );
  }),
);
