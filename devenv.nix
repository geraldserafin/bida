{ pkgs, ... }:
{
  packages = [ pkgs.pnpm ];

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

  process.manager.implementation = "process-compose";
  processes.api = {
    exec = "pnpm --filter @bida/api dev";
    process-compose.depends_on.postgres.condition = "process_healthy";
  };
  processes.docs.exec = "pnpm --filter @bida/docs dev";

  # The Flutter app: boots the emulator if needed and runs `flutter run` on it
  # (see start-mobile below). is_tty lets you type r / R for hot reload when the
  # process is focused in the process-compose TUI.
  processes.mobile = {
    exec = "start-mobile";
    process-compose = {
      is_tty = true;
      depends_on.api.condition = "process_started";
    };
  };

  scripts.start-mobile.exec = ''
    adb start-server >/dev/null
    if ! adb devices | grep -q '^emulator-'; then
      echo "starting emulator (log: $DEVENV_ROOT/.android/emu.log)..."
      mkdir -p "$DEVENV_ROOT/.android"
      setsid nohup emu >"$DEVENV_ROOT/.android/emu.log" 2>&1 &
    fi
    adb wait-for-device
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]; do
      sleep 2
    done
    cd "$DEVENV_ROOT/apps/mobile"
    exec flutter run "$@"
  '';

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
