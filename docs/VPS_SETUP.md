# Konfiguracja VPS-a pod bida

Notatka dla osoby z dostępem `sudo` na serwerze. Po zielonym CI na `main` GitHub Actions przez SSH wrzuca na VPS-a trzy rzeczy: obraz Dockera z API, zbudowaną apkę webową i zbudowanego Swaggera. Poniżej jest wszystko, co trzeba przygotować po stronie serwera; GitHub konfiguruje Gerald.

## Domeny

| Domena | Co tam jest |
| --- | --- |
| `api.bida.maknet.com.pl` | API (kontener `bida-api`, port 3000) |
| `app.bida.maknet.com.pl` | apka webowa (pliki statyczne) |
| `docs.bida.maknet.com.pl` | Swagger UI (pliki statyczne) |
| `bida.maknet.com.pl` | niezwiązana z deployem (przyszły landing) |

Trzy pierwsze muszą mieć rekordy DNS na ten serwer.

## Do zrobienia

1. **Użytkownik do deployu** z dostępem do Dockera, bez hasła i bez sudo:

   ```
   sudo adduser --disabled-password deploy
   sudo usermod -aG docker deploy
   ```

2. **Klucz SSH.** Gerald prześle klucz publiczny. Trzeba go dopisać do `/home/deploy/.ssh/authorized_keys` (katalog `.ssh` z uprawnieniami `700`, plik `600`, właściciel `deploy`).

3. **Katalog na pliki** (może być inny, wtedy podaj ścieżkę w odpowiedzi):

   ```
   sudo mkdir -p /srv/bida/web /srv/bida/docs
   sudo chown -R deploy: /srv/bida
   ```

4. **Baza.** Użytkownik `bida` i baza `bida` (właściciel: `bida`) w istniejącym Postgresie. Migracje API robi samo przy starcie, więc baza ma być pusta.

   ```
   CREATE ROLE bida LOGIN PASSWORD '<silne hasło>';
   CREATE DATABASE bida OWNER bida;
   ```

5. **Plik `/srv/bida/.env`** (właściciel `deploy`, uprawnienia `600`):

   ```
   DATABASE_URL=postgres://bida:<hasło>@<host-bazy>:5432/bida
   CORS_ORIGINS=https://app.bida.maknet.com.pl,https://docs.bida.maknet.com.pl
   PROXY_NETWORK=<nazwa sieci dockerowej, w której działa Caddy>
   ```

   - `<host-bazy>`: jeśli Postgres jest w kontenerze, to jego nazwa i musi być w tej samej sieci co `bida-api`. Jeśli działa na hoście, to `host.docker.internal`; wtedy Postgres musi słuchać na adresie mostka Dockera (zwykle `172.17.0.1`) i `pg_hba.conf` musi zezwalać na połączenia z `172.16.0.0/12` dla użytkownika `bida`.
   - `PROXY_NETWORK`: sprawdź przez `docker inspect <kontener caddy> -f '{{json .NetworkSettings.Networks}}'`. Kontener API dołączy do tej sieci, więc Caddy zobaczy go pod nazwą `bida-api`. Domyślnie `caddy`.

6. **Caddy w Dockerze.** Do kontenera Caddy trzeba zamontować katalogi ze statykami (tylko do odczytu):

   ```
   /srv/bida/web:/srv/bida/web:ro
   /srv/bida/docs:/srv/bida/docs:ro
   ```

   i dodać do Caddyfile:

   ```
   api.bida.maknet.com.pl {
       reverse_proxy bida-api:3000
   }

   app.bida.maknet.com.pl {
       root * /srv/bida/web
       try_files {path} /index.html
       file_server
   }

   docs.bida.maknet.com.pl {
       root * /srv/bida/docs
       file_server
   }
   ```

   Po zmianach przeładować Caddy (`docker exec <kontener caddy> caddy reload --config /etc/caddy/Caddyfile`; kontener trzeba odtworzyć, jeśli doszły nowe wolumeny).

7. **Uwaga o bezpieczeństwie.** API nie ma jeszcze kont, więc każdy, kto zna adres `api.bida…`, może czytać i zmieniać dane. Jeśli da się to łatwo ograniczyć po stronie Caddy (np. do IP), to warto.

## Co odesłać Geraldowi

- adres (IP albo nazwa) serwera i port SSH, jeśli inny niż 22,
- potwierdzenie nazwy użytkownika (`deploy`) i katalogu (`/srv/bida`), jeśli są inne niż powyżej,
- potwierdzenie, że Caddy i baza są skonfigurowane jak wyżej (nie trzeba podawać hasła do bazy, `.env` zostaje na serwerze).

Nie trzeba przesyłać żadnych kluczy prywatnych. Klucz SSH do deployu tworzy Gerald, a odcisk serwera (`ssh-keyscan`) pobierze sam.
