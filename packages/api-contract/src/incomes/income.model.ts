import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { PositiveMoney } from "../money.ts";
import { IsoDate, Note } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const IncomeId = Uuid.pipe(Schema.brand("IncomeId"));
export type IncomeId = typeof IncomeId.Type;

/** Money that came in, e.g. a salary. The only way money enters the app. */
export class Income extends Model.Class<Income>("Income")({
  id: Model.UuidV4Insert(IncomeId),
  userId: Model.Field({
    select: UserId,
    insert: UserId,
    update: UserId,
    json: UserId,
  }),
  amountMinor: PositiveMoney,
  receivedOn: IsoDate,
  note: Schema.NullOr(Note),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const IncomeJson = Income.json.annotate({ identifier: "Income" });

export const SaveIncome = Schema.Struct({
  amountMinor: PositiveMoney,
  receivedOn: IsoDate,
  note: Schema.NullOr(Note),
}).annotate({ identifier: "SaveIncome" });
export type SaveIncome = typeof SaveIncome.Type;

export class IncomeNotFound extends Schema.TaggedError<IncomeNotFound>()(
  "IncomeNotFound",
  { id: IncomeId },
  { httpApiStatus: 404 },
) {}
