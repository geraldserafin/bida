import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { wire } from "../errors.ts";
import { IsoDate } from "../text.ts";
import {
  AllocationId,
  AllocationJson,
  CreateAllocation,
  UpdateAllocation,
} from "./allocation.model.ts";
import {
  CreateEnvelope,
  EnvelopeId,
  EnvelopeJson,
  UpdateEnvelope,
} from "./envelope.model.ts";
import {
  AllocationNotFound,
  EnvelopeNotFound,
  Forbidden,
  NotEnoughMoney,
  ParentMustBeTopLevel,
} from "./envelopes.errors.ts";

export class EnvelopesApi extends HttpApiGroup.make("envelopes")
  .add(
    HttpApiEndpoint.get("list", "/envelopes", {
      success: Schema.Array(EnvelopeJson),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List envelopes",
        description:
          "Every envelope the user can see, top-level ones and their sub-envelopes, by name.",
      }),
    ),
    HttpApiEndpoint.get("get", "/envelopes/:id", {
      params: { id: EnvelopeId },
      success: EnvelopeJson,
      error: wire(EnvelopeNotFound),
    }).annotateMerge(OpenApi.annotations({ summary: "Get an envelope" })),
    HttpApiEndpoint.post("create", "/envelopes", {
      payload: CreateEnvelope,
      success: EnvelopeJson.pipe(HttpApiSchema.status(201)),
      error: [
        wire(EnvelopeNotFound),
        wire(ParentMustBeTopLevel),
        wire(Forbidden),
      ],
    }).annotateMerge(OpenApi.annotations({ summary: "Create an envelope" })),
    HttpApiEndpoint.put("update", "/envelopes/:id", {
      params: { id: EnvelopeId },
      payload: UpdateEnvelope,
      success: EnvelopeJson,
      error: [wire(EnvelopeNotFound), wire(Forbidden)],
    }).annotateMerge(OpenApi.annotations({ summary: "Edit an envelope" })),
    HttpApiEndpoint.delete("delete", "/envelopes/:id", {
      params: { id: EnvelopeId },
      error: [wire(EnvelopeNotFound), wire(Forbidden)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete an envelope",
        description:
          "Removes its sub-envelopes, expenses and allocations too; the money allocated to it goes back to the pools of the people who put it in.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Envelopes" })) {}

export class AllocationsApi extends HttpApiGroup.make("allocations")
  .add(
    HttpApiEndpoint.get("list", "/allocations", {
      query: {
        envelopeId: Schema.optional(EnvelopeId),
        /** Inclusive lower bound of `madeOn`. */
        from: Schema.optional(IsoDate),
        /** Inclusive upper bound of `madeOn`. */
        to: Schema.optional(IsoDate),
      },
      success: Schema.Array(AllocationJson),
      error: wire(EnvelopeNotFound),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "List allocations",
        description:
          "Of the envelope and, for a top-level one, its sub-envelopes (all envelopes when none is named). Newest first.",
      }),
    ),
    HttpApiEndpoint.post("create", "/allocations", {
      payload: CreateAllocation,
      success: AllocationJson.pipe(HttpApiSchema.status(201)),
      error: [wire(EnvelopeNotFound), wire(NotEnoughMoney)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Put money into an envelope or take it out",
        description:
          "A negative amount takes money back. Fails with 409 when an envelope would not have it, or when more would be assigned to sub-envelopes than the user put into the parent. A pool that goes below zero is allowed.",
      }),
    ),
    HttpApiEndpoint.put("update", "/allocations/:id", {
      params: { id: AllocationId },
      payload: UpdateAllocation,
      success: AllocationJson,
      error: [wire(AllocationNotFound), wire(NotEnoughMoney)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Edit an allocation",
        description: "Only the user who made it can.",
      }),
    ),
    HttpApiEndpoint.delete("delete", "/allocations/:id", {
      params: { id: AllocationId },
      error: [wire(AllocationNotFound), wire(NotEnoughMoney)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Delete an allocation",
        description: "Only the user who made it can.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Allocations" })) {}
