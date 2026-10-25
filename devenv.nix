{ pkgs, ... }:
{
  packages = [
    pkgs.pnpm
    pkgs.psmisc # fuser, used by the shutdown cleanup below
  ];

  env.DATABASE_URL = "postgres://bida@127.0.0.1:5432/bida";
  env.TEST_DATABASE_URL = "postgres://bida@127.0.0.1:5432/bida_test";

  services.postgres = {
    enable = true;
    listen_addresses = "127.0.0.1";
    port = 5432;
    initialDatabases = [
      { name = "bida"; }
      { name = "bida_test"; }
    ];
    initialScript = "CREATE ROLE bida SUPERUSER LOGIN;";
  };

  # Every process cleans up after itself when it is stopped, so nothing is left
  # holding a port or the database (strict_ports in devenv.yaml makes a busy
  # port an error instead of silently moving to the next one).
  process.manager.implementation = "process-compose";

  # Fast shutdown disconnects clients (the api, tests) instead of waiting for
  # them, so the postmaster really exits and releases port 5432 and the data dir.
  processes.postgres.process-compose.shutdown = {
    command = ''pg_ctl -D "$PGDATA" stop -m fast -w -t 20 || true'';
    timeout_seconds = 30;
  };

  # tsx is started directly (not through pnpm and sh) so the signal reaches it;
  # the port kill is the safety net for anything it left behind.
  processes.api = {
    exec = ''
      cd "$DEVENV_ROOT/apps/api"
      exec ./node_modules/.bin/tsx watch src/main.ts
    '';
    process-compose = {
      depends_on.postgres.condition = "process_healthy";
      shutdown.command = "fuser -k -TERM 3000/tcp || true";
    };
  };

  processes.docs = {
    exec = ''
      cd "$DEVENV_ROOT/apps/docs"
      exec ./node_modules/.bin/vite --port 5174
    '';
    process-compose.shutdown.command = "fuser -k -TERM 5174/tcp || true";
  };

  # The emulator runs in the foreground (`emu` ends with `exec emulator`), so
  # stopping or restarting this process stops or restarts the emulator. It is
  # healthy once Android has finished booting. is_tty forwards keyboard input to
  # the emulator when the process is focused in the process-compose TUI.
  processes.emulator = {
    exec = "emu";
    process-compose = {
      is_tty = true;
      # graceful stop, saves the quickboot snapshot
      shutdown.command = "adb -e emu kill || true";
      readiness_probe = {
        exec.command = ''[ "$(adb -e shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]'';
        initial_delay_seconds = 10;
        period_seconds = 3;
        failure_threshold = 100;
      };
    };
  };

  # The Flutter app on the emulator, started once the emulator is booted and
  # the api is up. is_tty lets you type r / R for hot reload when the process
  # is focused in the process-compose TUI. Restart it to rebuild.
  processes.mobile = {
    exec = ''
      cd "$DEVENV_ROOT/apps/mobile"
      exec flutter run -d emulator-5554
    '';
    process-compose = {
      is_tty = true;
      depends_on = {
        emulator.condition = "process_healthy";
        api.condition = "process_started";
      };
    };
  };

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
  };

  android = {
    enable = true;
    flutter.enable = true;
    platforms.version = [
      "35"
      "36"
    ];
    buildTools.version = [
      "35.0.0"
      "36.0.0"
    ];
    systemImageTypes = [ "google_apis" ];
    abis = [ "x86_64" ];
    emulator.enable = true;
  };

  enterShell = ''
    git config core.hooksPath .githooks
    setup-avd
  '';

  # Creates the "bida" virtual device if it does not exist yet. Idempotent, runs
  # on every shell entry so a fresh checkout has its emulator ready.
  scripts.setup-avd.exec = ''
    # build-tools and the NDK ship a libc++.so that shadows the emulator's own and
    # crashes it with undefined-symbol errors, so drop them from the lib path.
    export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -Ev '/(build-tools|ndk-bundle)/' | paste -sd:)
    mkdir -p "$ANDROID_AVD_HOME"
    if [ ! -d "$ANDROID_AVD_HOME/bida.avd" ]; then
      echo "creating emulator device 'bida'..."
      echo no | avdmanager create avd -n bida -k "system-images;android-36;google_apis;x86_64" -d pixel_6
      # default AVD is 1.5G RAM / 3 cores / no GPU, which is painfully slow
      cfg="$ANDROID_AVD_HOME/bida.avd/config.ini"
      sed -i -E '/^(hw.ramSize|hw.cpu.ncore|hw.gpu.enabled|hw.gpu.mode|vm.heapSize)/d' "$cfg"
      printf 'hw.ramSize = 3072\nhw.cpu.ncore = 4\nhw.gpu.enabled = yes\nhw.gpu.mode = host\nvm.heapSize = 512\n' >> "$cfg"
    fi
  '';

  scripts.emu.exec = ''
    setup-avd
    export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -Ev '/(build-tools|ndk-bundle)/' | paste -sd:)
    # host GPU + quickboot snapshot (first boot is cold, later ones take seconds)
    exec emulator -avd bida -no-audio -no-boot-anim -gpu host "$@"
  '';
}
