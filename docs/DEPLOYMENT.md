# Deployment

Po zielonym CI na `main` workflow `deploy.yml` buduje obraz API (`ghcr.io/geraldserafin/bida-api`), webową wersję apki i Swaggera, wysyła je przez SSH na VPS-a i restartuje API.

- `api.bida.maknet.com.pl` – API (usługa `backend` za Caddy)
- `app.bida.maknet.com.pl` – apka webowa (pliki statyczne z Caddy)
- `docs.bida.maknet.com.pl` – Swagger UI (pliki statyczne z Caddy)

## Serwer

Stos stoi w `/opt/bida`: `compose.yml` (Caddy jako `proxy`, Postgres jako `db`), `caddy/Caddyfile` i `.env` z danymi bazy. Deploy niczego z tego nie zmienia; jednorazowo dokłada:

- użytkownika `deploy` (grupa `docker`, logowanie tylko kluczem),
- usługę `backend` w `compose.override.yml` (ustawienia w `backend.env`),
- katalogi `/opt/bida/app` i `/opt/bida/docs` zamontowane w Caddy tylko do odczytu,
- bloki `app.` i `docs.` w Caddyfile.

Robi to skrypt `deploy/setup-server.sh`, uruchamiany jako root. Jest idempotentny, a przed zmianą Caddyfile robi kopię. Rekordy DNS dla `app.` i `docs.` trzeba dodać osobno.

```
ssh-keygen -t ed25519 -f bida-deploy -N "" -C bida-deploy
scp bida-deploy.pub deploy/setup-server.sh <użytkownik>@bida.maknet.com.pl:
ssh -t <użytkownik>@bida.maknet.com.pl sudo bash setup-server.sh bida-deploy.pub
```

## Konfiguracja w GitHubie

Settings → Secrets and variables → Actions:

| Nazwa | Rodzaj | Wartość |
| --- | --- | --- |
| `VPS_HOST` | secret | `bida.maknet.com.pl` |
| `VPS_USER` | secret | `deploy` |
| `VPS_SSH_KEY` | secret | zawartość pliku `bida-deploy` (klucz prywatny) |
| `VPS_KNOWN_HOSTS` | secret | wynik `ssh-keyscan bida.maknet.com.pl` |
| `VPS_DIR` | variable | `/opt/bida` |
| `VPS_PORT` | variable | port SSH, tylko jeśli inny niż 22 |

## Pierwszy deploy

1. Uruchom workflow Deploy (Actions → Deploy → Run workflow). Zbuduje i wypchnie obraz, ale ostatni krok padnie, bo pakiet w ghcr jest jeszcze prywatny.
2. GitHub → Packages → `bida-api` → Package settings → Change visibility → Public.
3. Uruchom Deploy jeszcze raz.

Sprawdzenie: `https://api.bida.maknet.com.pl/health` zwraca `{"status":"ok",...}`.

API nie ma jeszcze kont, więc każdy, kto zna adres, może czytać i zmieniać dane.
