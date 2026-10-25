import { Schema } from "effect";
import { RecurringRuleId } from "./recurring.model.ts";

export class RecurringRuleNotFound extends Schema.TaggedError<RecurringRuleNotFound>()(
  "RecurringRuleNotFound",
  { id: RecurringRuleId },
  { httpApiStatus: 404 },
) {}
