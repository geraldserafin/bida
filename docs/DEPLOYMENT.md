# Deployment

Po zielonym CI na `main` workflow `deploy.yml` buduje obraz API (`ghcr.io/geraldserafin/bida-api`), webową wersję apki i Swaggera, wysyła je przez SSH na VPS-a i restartuje API.

- `api.bida.maknet.com.pl` – API (Caddy → `127.0.0.1:3000`)
- `bida.maknet.com.pl` – apka webowa (pliki statyczne z Caddy)
- `docs.bida.maknet.com.pl` – Swagger UI (pliki statyczne z Caddy)

## Jednorazowa konfiguracja VPS-a

1. Użytkownik do deployu z dostępem do Dockera (`docker` w grupie) i katalog `VPS_DIR`, np. `/srv/bida`, w którym leży `.env`:

   ```
   DATABASE_URL=postgres://bida:<hasło>@127.0.0.1:5432/bida
   CORS_ORIGINS=https://bida.maknet.com.pl,https://docs.bida.maknet.com.pl
   ```

   Baza `bida` i jej użytkownik muszą istnieć; migracje API wykonuje samo przy starcie.

2. Pobieranie obrazu z ghcr: pakiet jest prywatny, więc jednorazowo `docker login ghcr.io` na VPS-ie (token z uprawnieniem `read:packages`) albo ustaw pakiet jako publiczny.

3. Caddy:

   ```
   api.bida.maknet.com.pl {
       reverse_proxy 127.0.0.1:3000
   }

   bida.maknet.com.pl {
       root * /srv/bida/web
       try_files {path} /index.html
       file_server
   }

   docs.bida.maknet.com.pl {
       root * /srv/bida/docs
       file_server
   }
   ```

## Sekrety i zmienne w GitHubie

| Nazwa | Rodzaj | Znaczenie |
| --- | --- | --- |
| `VPS_HOST` | secret | adres VPS-a |
| `VPS_USER` | secret | użytkownik do deployu |
| `VPS_SSH_KEY` | secret | prywatny klucz (osobny, tylko do deployu) |
| `VPS_KNOWN_HOSTS` | secret | wynik `ssh-keyscan <host>` |
| `VPS_DIR` | variable | katalog na VPS-ie, np. `/srv/bida` |

API nie ma jeszcze kont, więc po wystawieniu do internetu każdy zna adres może czytać i zmieniać dane. Do czasu kont zabezpiecz je w Caddy (np. `basic_auth`).
