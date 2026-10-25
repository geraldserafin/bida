import { Api } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpApiBuilder } from "effect/http-api";
import { requireOwner } from "../../platform/space.ts";
import { CategoriesService } from "./categories.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const CategoriesHttp = HttpApiBuilder.group(
  Api,
  "categories",
  Effect.fn(function* (handlers) {
    const categories = yield* CategoriesService;
    return handlers
      .handle("list", () => categories.list)
      .handle("get", ({ params }) => categories.get(params.id))
      .handle("create", ({ payload }) => categories.create(payload))
      .handle("update", ({ params, payload }) =>
        categories.update(params.id, payload),
      )
      .handle("delete", ({ params }) =>
        Effect.andThen(requireOwner, categories.remove(params.id)),
      );
  }),
);
