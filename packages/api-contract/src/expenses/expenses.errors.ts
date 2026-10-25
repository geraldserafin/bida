import { Schema } from "effect";
import { ExpenseId } from "./expense.model.ts";

export class ExpenseNotFound extends Schema.TaggedError<ExpenseNotFound>()(
  "ExpenseNotFound",
  { id: ExpenseId },
  { httpApiStatus: 404 },
) {}
