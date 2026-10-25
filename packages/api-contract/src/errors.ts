import { Schema } from "effect";

const named = new WeakMap<object, unknown>();

/**
 * Names the response schema of an error after its class. Without it OpenAPI
 * calls the wire form `<Name>Encoded`, which then leaks into generated clients.
 *
 * The result is cached per class: every call has to return the same schema,
 * otherwise OpenAPI sees many schemas with one name and numbers them
 * (`CategoryNotFound_3`).
 */
export const wire = <S extends Schema.Top & { readonly identifier: string }>(
  error: S,
): S => {
  const known = named.get(error);
  if (known !== undefined) return known as S;
  const annotated = error.pipe(
    Schema.annotateEncoded({ identifier: error.identifier }),
  ) as unknown as S;
  named.set(error, annotated);
  return annotated;
};
