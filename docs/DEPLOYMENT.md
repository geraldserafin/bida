# Deployment

Po zielonym CI na `main` workflow `deploy.yml` buduje obraz API (`ghcr.io/geraldserafin/bida-api`), webową wersję apki i Swaggera, wysyła je przez SSH na VPS-a i restartuje API.

- `api.bida.maknet.com.pl` – API (kontener `bida-api`, za Caddy)
- `app.bida.maknet.com.pl` – apka webowa (pliki statyczne z Caddy)
- `docs.bida.maknet.com.pl` – Swagger UI (pliki statyczne z Caddy)

Przygotowanie serwera (użytkownik, baza, `.env`, Caddy) jest opisane w [VPS_SETUP.md](VPS_SETUP.md).

## Konfiguracja w GitHubie

Settings → Secrets and variables → Actions:

| Nazwa | Rodzaj | Znaczenie |
| --- | --- | --- |
| `VPS_HOST` | secret | adres VPS-a |
| `VPS_USER` | secret | użytkownik do deployu (`deploy`) |
| `VPS_SSH_KEY` | secret | prywatny klucz, osobny, tylko do deployu |
| `VPS_KNOWN_HOSTS` | secret | wynik `ssh-keyscan <host>` |
| `VPS_DIR` | variable | katalog na VPS-ie, np. `/srv/bida` |
| `VPS_PORT` | variable | port SSH, tylko jeśli inny niż 22 |

Klucz SSH:

```
ssh-keygen -t ed25519 -f bida-deploy -N "" -C bida-deploy
```

Plik `bida-deploy.pub` idzie do osoby, która ma dostęp do serwera, a `bida-deploy` do `VPS_SSH_KEY`.

## Pierwszy deploy

1. Uruchom workflow Deploy (Actions → Deploy → Run workflow). Zbuduje i wypchnie obraz, ale ostatni krok padnie, bo pakiet w ghcr jest jeszcze prywatny.
2. GitHub → Packages → `bida-api` → Package settings → Change visibility → Public.
3. Uruchom Deploy jeszcze raz.

Sprawdzenie: `https://api.bida.maknet.com.pl/health` zwraca `{"status":"ok",...}`.
