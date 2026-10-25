import { Api, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { TransferService } from "./transfer.service.ts";

const userId = Effect.map(CurrentUser, ({ user }) => user.id);

/** Thin adapter: decoded request in, service call, domain errors out. */
export const TransferHttp = HttpApiBuilder.group(
  Api,
  "transfer",
  Effect.fn(function* (handlers) {
    const transfer = yield* TransferService;
    return handlers
      .handle("export", () => Effect.flatMap(userId, transfer.export))
      .handle("previewImport", ({ payload }) =>
        Effect.flatMap(userId, (id) => transfer.previewImport(id, payload)),
      )
      .handle("import", ({ payload }) =>
        Effect.flatMap(userId, (id) => transfer.importDocument(id, payload)),
      )
      .handle("importLegacy", ({ payload }) =>
        Effect.flatMap(userId, (id) => transfer.importLegacy(id, payload)),
      )
      .handle("exportCsv", () => Effect.flatMap(userId, transfer.exportCsv))
      .handle("importCsv", ({ payload }) =>
        Effect.flatMap(userId, (id) => transfer.importCsv(id, payload)),
      );
  }),
);
