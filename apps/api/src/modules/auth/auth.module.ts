import { Layer } from "effect";
import { AuthRepository } from "./auth.repository.ts";
import { AuthService } from "./auth.service.ts";
import { AuthenticatedLive } from "./authenticated.ts";

export { AuthHttp } from "./auth.http.ts";
export { AuthService } from "./auth.service.ts";
export { GoogleVerifier } from "./google.ts";

/**
 * Public surface of the module: exposes `AuthService`. Requires `SqlClient`,
 * `Mailer` and `GoogleVerifier`.
 */
export const AuthModule = AuthService.layer.pipe(
  Layer.provide(AuthRepository.layer),
);

/**
 * The `Authenticated` middleware that every endpoint behind a sign-in is
 * wrapped in. Needs `AuthService`, so provide it next to `AuthModule`.
 */
export const AuthenticatedModule = AuthenticatedLive.pipe(
  Layer.provide(AuthModule),
);
