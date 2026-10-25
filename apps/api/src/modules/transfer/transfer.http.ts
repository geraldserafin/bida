import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
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
      .handle("import", ({ payload }) => transfer.importDocument(payload))
      .handle("importLegacy", ({ payload }) => transfer.importLegacy(payload))
      .handle("exportCsv", () => transfer.exportCsv)
      .handle("importCsv", ({ payload }) => transfer.importCsv(payload));
  }),
);
