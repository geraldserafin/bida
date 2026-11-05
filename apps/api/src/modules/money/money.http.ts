import { Api, CurrentUser, type User } from "@bida/api-contract";
import { type Context, Effect, Layer } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import type { SqlClient } from "effect/sql";
import { Mailer } from "../../platform/mailer.ts";
import { account } from "../account/account.module.ts";
import { envelopes } from "../envelopes/envelopes.module.ts";
import { expenses } from "../expenses/expenses.module.ts";
import { households, log, members } from "../households/households.module.ts";
import { recurring } from "../recurring/recurring.module.ts";
import { sync } from "../sync/sync.module.ts";
import { wallet } from "../wallet/wallet.module.ts";

// Thin adapters: decoded request in, the signed-in user, a service call,
// domain errors out.

type Services = SqlClient.SqlClient | Mailer;

const me = Effect.map(CurrentUser, ({ user }) => user.id);

/**
 * Builds the handlers of a group with the database and the mailer of the
 * layer: `as(f)` calls `f` with the signed-in user.
 */
const withServices = <H>(
  build: (
    as: <A, E>(
      f: (userId: User["id"]) => Effect.Effect<A, E, Services>,
    ) => Effect.Effect<A, E, CurrentUser>,
  ) => H,
) =>
  Effect.gen(function* () {
    yield* Mailer;
    const services: Context.Context<Services> =
      yield* Effect.context<Services>();
    return build((f) =>
      Effect.flatMap(me, (id) => Effect.provideContext(f(id), services)),
    );
  });

export const AccountHttp = HttpApiBuilder.group(Api, "account", (handlers) =>
  withServices((as) =>
    handlers
      .handle("update", ({ payload }) =>
        as((id) => account.setName(id, payload.name)),
      )
      .handle("delete", ({ payload }) =>
        as((id) => account.remove(id, payload.email)),
      ),
  ),
);

export const SyncHttp = HttpApiBuilder.group(Api, "sync", (handlers) =>
  withServices((as) =>
    handlers
      .handle("run", () => as(sync.run))
      .handle("summaries", () => as(sync.summaries))
      .handle("seen", ({ params }) => as((id) => sync.seen(id, params.id)))
      .handle("todo", () => as(sync.todo))
      .handle("resolve", ({ params, payload }) =>
        as((id) => sync.resolve(id, params.id, payload)),
      )
      .handle("dismiss", ({ params }) =>
        as((id) => sync.dismiss(id, params.id)),
      )
      .handle("overview", ({ query }) =>
        as((id) => sync.overview(id, query.from, query.to)),
      ),
  ),
);

export const WalletHttp = HttpApiBuilder.group(Api, "wallet", (handlers) =>
  withServices((as) =>
    handlers
      .handle("get", () => as(wallet.get))
      .handle("entries", ({ query }) =>
        as((id) => wallet.entries(id, query.limit, query.offset)),
      )
      .handle("addIncome", ({ payload }) =>
        as((id) => wallet.addIncome(id, payload)),
      )
      .handle("updateIncome", ({ params, payload }) =>
        as((id) => wallet.updateIncome(id, params.id, payload)),
      )
      .handle("confirmIncome", ({ params, payload }) =>
        as((id) =>
          wallet.confirmIncome(
            id,
            params.id,
            payload.amountMinor,
            payload.correction,
          ),
        ),
      )
      .handle("removeIncome", ({ params, payload }) =>
        as((id) => wallet.removeIncome(id, params.id, payload.correction)),
      ),
  ),
);

export const HouseholdsHttp = HttpApiBuilder.group(
  Api,
  "households",
  (handlers) =>
    withServices((as) =>
      handlers
        .handle("list", () => as(households.list))
        .handle("create", ({ payload }) =>
          as((id) => households.create(id, payload)),
        )
        .handle("get", ({ params }) =>
          as((id) => households.get(id, params.id)),
        )
        .handle("rename", ({ params, payload }) =>
          as((id) => households.rename(id, params.id, payload.name)),
        )
        .handle("delete", ({ params }) =>
          as((id) => households.remove(id, params.id)),
        )
        .handle("setCycle", ({ params, payload }) =>
          as((id) => households.setCycle(id, params.id, payload.cycle)),
        )
        .handle("periods", ({ params }) =>
          as((id) => households.periods(id, params.id)),
        )
        .handle("openNext", ({ params }) =>
          as((id) => households.openNextPeriod(id, params.id)),
        )
        .handle("period", ({ params, query }) =>
          as((id) => households.summary(id, params.id, query.forWhom)),
        )
        .handle("setEnd", ({ params, payload }) =>
          as((id) => households.setEnd(id, params.id, payload.endsOn)),
        )
        .handle("moves", ({ params }) =>
          as((id) => households.moves(id, params.id)),
        )
        .handle("transfer", ({ params, payload }) =>
          as((id) => households.transfer(id, params.id, payload.amountMinor)),
        )
        .handle("withdraw", ({ params, payload }) =>
          as((id) => households.withdraw(id, params.id, payload.amountMinor)),
        )
        .handle("log", ({ params }) => as((id) => log.list(id, params.id)))
        .handle("undo", ({ params }) => as((id) => log.undo(id, params.id))),
    ),
);

export const MembersHttp = HttpApiBuilder.group(Api, "members", (handlers) =>
  withServices((as) =>
    handlers
      .handle("list", ({ params }) => as((id) => members.list(id, params.id)))
      .handle("setRole", ({ params, payload }) =>
        as((id) => members.setRole(id, params.id, params.userId, payload.role)),
      )
      .handle("remove", ({ params }) =>
        as((id) => members.remove(id, params.id, params.userId)),
      )
      .handle("freeze", ({ params }) =>
        as((id) => members.freeze(id, params.id, params.userId, true)),
      )
      .handle("unfreeze", ({ params }) =>
        as((id) => members.freeze(id, params.id, params.userId, false)),
      )
      .handle("leave", ({ params, payload }) =>
        as((id) => members.leave(id, params.id, payload.withdraw)),
      )
      .handle("invite", ({ params, payload }) =>
        as((id) =>
          members.invite(
            id,
            params.id,
            payload.email,
            payload.role ?? "member",
          ),
        ),
      )
      .handle("invitations", ({ params }) =>
        as((id) => members.invitations(id, params.id)),
      )
      .handle("revoke", ({ params }) =>
        as((id) => members.revoke(id, params.id, params.invitationId)),
      )
      .handle("mine", () => as(members.mine))
      .handle("accept", ({ params }) =>
        as((id) => members.accept(id, params.id)),
      )
      .handle("decline", ({ params }) =>
        as((id) => members.decline(id, params.id)),
      ),
  ),
);

export const EnvelopesHttp = HttpApiBuilder.group(
  Api,
  "envelopes",
  (handlers) =>
    withServices((as) =>
      handlers
        .handle("list", ({ params }) =>
          as((id) => envelopes.list(id, params.id)),
        )
        .handle("create", ({ params, payload }) =>
          as((id) => envelopes.create(id, params.id, payload)),
        )
        .handle("update", ({ params, payload }) =>
          as((id) => envelopes.update(id, params.id, payload)),
        )
        .handle("delete", ({ params }) =>
          as((id) => envelopes.remove(id, params.id)),
        )
        .handle("archive", ({ params }) =>
          as((id) => envelopes.archive(id, params.id, true)),
        )
        .handle("unarchive", ({ params }) =>
          as((id) =>
            envelopes
              .archive(id, params.id, false)
              .pipe(Effect.catchTag("LastEnvelope", Effect.die)),
          ),
        )
        .handle("setPlan", ({ params, payload }) =>
          as((id) =>
            envelopes.setPlan(
              id,
              params.id,
              params.envelopeId,
              payload.amountMinor,
            ),
          ),
        ),
    ),
);

export const ExpensesHttp = HttpApiBuilder.group(Api, "expenses", (handlers) =>
  withServices((as) =>
    handlers
      .handle("create", ({ params, payload }) =>
        as((id) => expenses.create(id, params.id, payload)),
      )
      .handle("get", ({ params }) => as((id) => expenses.get(id, params.id)))
      .handle("update", ({ params, payload }) =>
        as((id) => expenses.update(id, params.id, payload)),
      )
      .handle("delete", ({ params }) =>
        as((id) => expenses.remove(id, params.id)),
      )
      .handle("list", ({ query }) => as((id) => expenses.list(id, query))),
  ),
);

export const RecurringHttp = HttpApiBuilder.group(
  Api,
  "recurring",
  (handlers) =>
    withServices((as) =>
      handlers
        .handle("list", () => as(recurring.list))
        .handle("create", ({ payload }) =>
          as((id) => recurring.create(id, payload)),
        )
        .handle("update", ({ params, payload }) =>
          as((id) => recurring.update(id, params.id, payload)),
        )
        .handle("delete", ({ params }) =>
          as((id) => recurring.remove(id, params.id)),
        )
        .handle("apply", ({ params, payload }) =>
          as((id) => recurring.apply(id, params.id, payload.amountMinor)),
        )
        .handle("applyAll", ({ params }) =>
          as((id) => recurring.applyAll(id, params.id)),
        ),
    ),
);

export const MoneyHttp = Layer.mergeAll(
  AccountHttp,
  SyncHttp,
  WalletHttp,
  HouseholdsHttp,
  MembersHttp,
  EnvelopesHttp,
  ExpensesHttp,
  RecurringHttp,
);
