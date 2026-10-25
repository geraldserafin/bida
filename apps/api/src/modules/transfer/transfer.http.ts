import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { requireOwner } from "../../platform/space.ts";
import { TransferService } from "./transfer.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const TransferHttp = HttpApiBuilder.group(
  Api,
  "transfer",
  Effect.fn(function* (handlers) {
    const transfer = yield* TransferService;
    return handlers
      .handle("export", () => transfer.export)
      .handle("previewImport", ({ payload }) => transfer.previewImport(payload))
      .handle("import", ({ payload }) =>
        Effect.andThen(requireOwner, transfer.importDocument(payload)),
      )
      .handle("importLegacy", ({ payload }) =>
        Effect.andThen(requireOwner, transfer.importLegacy(payload)),
      )
      .handle("exportCsv", () => transfer.exportCsv)
      .handle("importCsv", ({ payload }) => transfer.importCsv(payload));
  }),
);
