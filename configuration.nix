{ lib, pkgs, ... }:
let
  tmpFilesUserName = "mentalblood";
  tmpFilesUserGroup = "users";
  tmpFilesHomeDir = "/home/${tmpFilesUserName}";
  mkTmpfile = type: content: {
    "${type}" = {
      user = "${tmpFilesUserName}";
      group = "${tmpFilesUserGroup}";
      mode = "1700";
    }
    // lib.optionalAttrs (content != null) {
      argument = if (type == "L+") then "${pkgs.writeScript "tmpfile-content" content}" else content;
    };
  };
  dir = mkTmpfile "d" null;
  link = content: mkTmpfile "L+" content;
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
  ollamaBin = "${pkgs.ollama}/bin/ollama";
  ollama-wrapper-script = pkgs.writeShellScriptBin "ollama-wrapper-script" ''
    exec ${ollamaBin} "$@"
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];
  nix.settings = {
    # substituters = [
    #   "https://cache.nixos.org"
    #   "https://aseipp-nix-cache.global.ssl.fastly.net"
    # ];
    # stalled-download-timeout = 5;
    download-attempts = 1;
    connect-timeout = 2;
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    keyboard.qmk.enable = true;
  };
  system.copySystemConfiguration = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  time.timeZone = "Europe/Moscow";
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    # proxy = {
    #   default = "http://127.0.0.1:2080";
    #   noProxy = "127.0.0.1,localhost,internal.domain";
    # };
    firewall = {
      allowedTCPPorts = [
        42000
        42001
        4533
        2234
      ];
      allowedUDPPorts = [
        42000
        42001
        4533
        2234
      ];
      allowedUDPPortRanges = [
        {
          from = 5353;
          to = 5353;
        }
      ];
    };
    bridges."ollama_net".interfaces = [ ];
    interfaces."ollama_net" = {
      virtual = true;
      ipv4.addresses = [
        {
          address = "10.0.0.1";
          prefixLength = 24;
        }
      ];
    };
  };
  i18n.defaultLocale = "en_US.UTF-8";
  users.users.mentalblood = {
    isNormalUser = true;
    description = "mentalblood";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
  systemd.tmpfiles.settings = {
    "00-config" = {
      "${tmpFilesHomeDir}/.config" = dir;
    };
    "10-tmux-config" = {
      "${tmpFilesHomeDir}/.tmux.conf" = link ''
        # remove delay after pressing ESC in helix
        set -sg escape-time 0

        # kill the session when the last client detaches
        set-hook client-detached kill-session

        # fix colors in helix
        set -g default-terminal "tmux-256color"
        set -as terminal-features ",xterm-256color:RGB"

        # use fish as default shell
        set-option -g default-shell ${pkgs.fish}/bin/fish

        # bar
        set -g status off

        # insert pane
        bind -n M-p split-window -v
        bind -n M-y split-window -h

        # remove pane
        bind -n M-m kill-pane

        # select pane
        bind -n M-h select-pane -L
        bind -n M-j select-pane -D
        bind -n M-k select-pane -U
        bind -n M-l select-pane -R

        # move pane
        bind-key -n "M-H" run-shell 'old=`tmux display -p "#{pane_index}"`; tmux select-pane -L; tmux swap-pane -t $old'
        bind-key -n "M-J" run-shell 'old=`tmux display -p "#{pane_index}"`; tmux select-pane -D; tmux swap-pane -t $old'
        bind-key -n "M-K" run-shell 'old=`tmux display -p "#{pane_index}"`; tmux select-pane -U; tmux swap-pane -t $old'
        bind-key -n "M-L" run-shell 'old=`tmux display -p "#{pane_index}"`; tmux select-pane -R; tmux swap-pane -t $old'

        # maximize pane
        bind-key -n "M-f" resize-pane -Z

        # insert window
        bind -n M-o new-window

        # select window
        bind -n M-u previous-window
        bind -n M-i next-window
        bind -n M-0 select-window -t 0
        bind -n M-1 select-window -t 1
        bind -n M-2 select-window -t 2
        bind -n M-3 select-window -t 3
        bind -n M-4 select-window -t 4
        bind -n M-5 select-window -t 5
        bind -n M-6 select-window -t 6
        bind -n M-7 select-window -t 7
        bind -n M-8 select-window -t 8
        bind -n M-9 select-window -t 9

        # reload config
        bind -n M-c source-file ~/.tmux.conf \; display "config reloaded"

        # thicker borders
        set -g pane-border-lines "single"
        set -g pane-active-border-style fg=colour2,bg=colour2
      '';
    };
    "10-alacritty-config" = {
      "${tmpFilesHomeDir}/.config/alacritty" = dir;
      "${tmpFilesHomeDir}/.config/alacritty/alacritty.toml" = link ''
        [general]
        import = ["~/.config/alacritty/themes/modus-operandi-tinted.toml"]

        [terminal.shell]
        program = "${pkgs.fish}/bin/fish"
        args = ["--login"]

        [font]
        size = 11
      '';
      "${tmpFilesHomeDir}/.config/alacritty/themes" = dir;
      "${tmpFilesHomeDir}/.config/alacritty/themes/modus-operandi-tinted.toml" = link ''
        # Colors Modus-Operandi-Tinted
        [colors.normal]
        black = '#efe9dd'
        red = '#a60000'
        green = '#006800'
        yellow = '#6f5500'
        blue = '#0031a9'
        magenta = '#721045'
        cyan = '#005e8b'
        white = '#000000'
        [colors.bright]
        black = '#c9b9b0'
        red = '#a0132f'
        green = '#00663f'
        yellow = '#7a4f2f'
        blue = '#0000b0'
        magenta = '#531ab6'
        cyan = '#005f5f'
        white = '#595959'
        [colors.cursor]
        cursor = '#000000'
        text = '#fbf7f0'
        [colors.primary]
        background = '#fbf7f0'
        foreground = '#000000'
        [colors.selection]
        background = '#c2bcb5'
        text = '#000000'
      '';
    };
    "10-fish-config" = {
      "${tmpFilesHomeDir}/.config/fish" = dir;
      "${tmpFilesHomeDir}/.config/fish/config.fish" = link ''
        set -x TMPDIR /tmp/
        set fish_greeting ""

        if status is-interactive
            fish_add_path ~/.local/bin
            fish_add_path ~/.config/scripts

            set XDG_CONFIG_HOME ~/.config
            set SHELL fish
            ulimit -n 8192
            if not set -q TMUX
                exec tmux
            end
        end
      '';
    };
    "10-helix-config" = {
      "${tmpFilesHomeDir}/.config/helix" = dir;
      "${tmpFilesHomeDir}/.config/helix/config.toml" = link ''
        theme = "modus_operandi_tinted"

        [editor]
        mouse = false
        scrolloff = 0
        cursorline = true
        cursorcolumn = true
        true-color = true
        gutters = []
        completion-timeout = 5
        auto-pairs = true

        [editor.soft-wrap]
        enable = true

        [editor.cursor-shape]
        insert = "bar"
        normal = "block"
        select = "underline"

        [editor.file-picker]
        hidden = false

        [keys.normal]
        S-j = "@jjjjj"
        S-k = "@kkkkk"
        "ш" = "@i"

        [keys.normal.space]
        w = ":update"
        "ц" = ":write"
        q = ":quit"
        m = ":bc!"

        [keys.insert]
        C-left = "@<esc>bi"
        C-right = "@<esc>wa"
        esc = ["normal_mode", ":update"]
      '';
      "${tmpFilesHomeDir}/.config/helix/languages.toml" = link ''
        [language-server.fs_watcher_lsp]
        command = "fs_watcher_lsp" # maybe use the path where it is installed
        args = []

        [[language]]
        name = "nix"
        auto-format = true
        formatter = { command = "nixfmt" }

        [[language]]
        name = "toml"
        auto-format = true
        formatter = { command = "taplo", args = ["fmt", "-"] }

        [[language]]
        name = "json"
        auto-format = true
        formatter = { command = "fixjson" }

        [[language]]
        name = "cpp"
        auto-format = true
        formatter = { command = "clang-format" }

        [[language]]
        name = "crystal"
        auto-format = true
        formatter = { command = "crystal", args = ["tool", "format", "-"] }

        [[language]]
        name = "rust"
        formatter = { command = "rustfmt", args = ["--config", "format_strings=true", "--edition", "2024"] }
        auto-format = true

        [language.auto-pairs]
        '{' = '}'
        '[' = ']'
        '"' = '"'
        '`' = '`'


        [[language]]
        name = "yaml"
        auto-format = false
        formatter = { command = "yamlfmt", args = ["-in"] }
        language-servers = ["fs_watcher_lsp"]

        [[language]]
        name = "c-sharp"
        auto-format = true
        formatter = { command = "dotnet-csharpier", args = [
          "--no-cache",
          "--no-msbuild-check",
          "--fast",
        ] }

        [[language]]
        name = "javascript"
        auto-format = true
        formatter = { command = "js-beautify" }
      '';
    };
    "10-niri-config" = {
      "${tmpFilesHomeDir}/.config/niri" = dir;
      "${tmpFilesHomeDir}/.config/niri/config.kdl" = link ''
        input {
            keyboard {
                repeat-delay 250
                repeat-rate 42
                xkb {
                    layout "us,ru"
                }
                numlock
            }
            warp-mouse-to-focus
            focus-follows-mouse
        }
        gestures {
          hot-corners {
            off
          }
        }
        output "HKC OVERSEAS LIMITED Smart TV Unknown" {
            mode "3840x2160@60.000"
            scale 1.4
        }
        layout {
            background-color "transparent"
            gaps 16
            center-focused-column "never"
            preset-column-widths {
                proportion 0.33333
                proportion 0.5
                proportion 0.66667
            }
            default-column-width { proportion 0.5; }
            focus-ring {
                width 4
                active-color "#ff9955ff"
                inactive-color "#22448855"
            }
            shadow {
                on
                softness 30
                spread 5
                offset x=0 y=5
                color "#0007"
            }
        }
        spawn-at-startup "waybar"
        spawn-at-startup "throne"
        spawn-at-startup "awww-daemon"
        hotkey-overlay {
            skip-at-startup
        }
        prefer-no-csd
        screenshot-path "~/screenshots/%Y-%m-%d %H-%M-%S.png"
        animations {
            slowdown 1.0
        }
        layer-rule {
            match namespace="^awww-daemon$"
            place-within-backdrop true
        }
        window-rule {
            background-effect {
                blur true
                saturation 0.8 
            }
            draw-border-with-background false
            geometry-corner-radius 8
            clip-to-geometry true
        }
        window-rule {
            match is-focused=true
            opacity 0.84
        }
        window-rule {
            match is-focused=false
            opacity 0.7
        }
        binds {
            Mod+C { spawn "pkill" "-SIGUSR2" "waybar"; }
            Mod+Return { spawn "alacritty"; }
            Mod+D { spawn "fuzzel" "--terminal" "alacritty -e"; }
            Super+Alt+L { spawn "swaylock"; }
            XF86AudioRaiseVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"; }
            XF86AudioLowerVolume allow-when-locked=true { spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"; }
            XF86AudioMute        allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"; }
            XF86AudioMicMute     allow-when-locked=true { spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"; }
            XF86AudioPlay        allow-when-locked=true { spawn-sh "playerctl play-pause"; }
            XF86AudioStop        allow-when-locked=true { spawn-sh "playerctl stop"; }
            XF86AudioPrev        allow-when-locked=true { spawn-sh "playerctl previous"; }
            XF86AudioNext        allow-when-locked=true { spawn-sh "playerctl next"; }
            Mod+O repeat=false { toggle-overview; }
            Mod+M repeat=false { close-window; }
            Mod+H     { focus-column-left; }
            Mod+J     { focus-window-down; }
            Mod+K     { focus-window-up; }
            Mod+L     { focus-column-right; }
            Mod+Ctrl+H     { move-column-left; }
            Mod+Ctrl+J     { move-window-down; }
            Mod+Ctrl+K     { move-window-up; }
            Mod+Ctrl+L     { move-column-right; }
            Mod+I              { focus-workspace-down; }
            Mod+U              { focus-workspace-up; }
            Mod+Ctrl+U         { move-column-to-workspace-down; }
            Mod+Ctrl+I         { move-column-to-workspace-up; }
            Mod+Shift+U         { move-workspace-down; }
            Mod+Shift+I         { move-workspace-up; }
            Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
            Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
            Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
            Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }
            Mod+Ctrl+1 { move-column-to-workspace 1; }
            Mod+Ctrl+2 { move-column-to-workspace 2; }
            Mod+Ctrl+3 { move-column-to-workspace 3; }
            Mod+Ctrl+4 { move-column-to-workspace 4; }
            Mod+Ctrl+5 { move-column-to-workspace 5; }
            Mod+Ctrl+6 { move-column-to-workspace 6; }
            Mod+Ctrl+7 { move-column-to-workspace 7; }
            Mod+Ctrl+8 { move-column-to-workspace 8; }
            Mod+Ctrl+9 { move-column-to-workspace 9; }
            Mod+BracketLeft  { consume-or-expel-window-left; }
            Mod+BracketRight { consume-or-expel-window-right; }
            Mod+Comma  { consume-window-into-column; }
            Mod+Period { expel-window-from-column; }
            Mod+R { switch-preset-column-width; }
            Mod+F { maximize-column; }
            Mod+Ctrl+F { fullscreen-window; }
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            Mod+V       { toggle-window-floating; }
            Mod+Ctrl+V { switch-focus-between-floating-and-tiling; }
            Mod+Space       { switch-layout "next"; }
            Print { screenshot; }
            Ctrl+Print { screenshot-screen; }
            Alt+Print { screenshot-window; }
            // Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
            Mod+Shift+E { quit; }
            Mod+Shift+P { power-off-monitors; }
        }
      '';
    };
    "10-nsxiv-config" = {
      "${tmpFilesHomeDir}/.config/nsxiv" = dir;
      "${tmpFilesHomeDir}/.config/nsxiv/exec" = dir;
      "${tmpFilesHomeDir}/.config/nsxiv/exec/key-handler" = link ''
        #! /usr/bin/env fish

        clear

        switch "$argv[1]"
            case C-b
                while IFS= read file
                    cp "$file" /mnt/merged/pictures/other/best/
                end
            case C-o
                while IFS= read file
                    mv "$file" /mnt/merged/wallpapers/desktop
                end
            case C-p
                while IFS= read file
                    cp -b "$file" /mnt/merged/pictures/other/photo/
                end
            case C-d
                while IFS= read file
                    rm "$file"
                end
            case C-w
                IFS= read file
                magick $file -resize 3840x2160^ -gravity center -extent 3840x2160 ~/.config/wallpaper.png &&
                    magick ~/.config/wallpaper.png -sigmoidal-contrast 3,60% -gamma 1.65 -colors 19 -depth 8 -format "%c" histogram:info: | sed 's/^.*#\([0-9A-Fa-f]\{6\}\) .*/@define-color color_# #\1;/;1,5d' | awk '{gsub("color_#", "color_" NR); print}' >~/.config/waybar/colors.css &&
                    awww img ~/.config/wallpaper.png &&
                    pkill -SIGUSR2 waybar
        end
      '';
    };
    "10-zathura-config" = {
      "${tmpFilesHomeDir}/.config/zathura" = dir;
      "${tmpFilesHomeDir}/.config/zathura/zathurarc" = link ''
        set window-title-basename "true"
        set selection-clipboard "clipboard"


        # set recolor-lightcolor          "#f2f0e9"
        # set recolor-darkcolor           "#383226"
        set recolor-lightcolor          "#1F1F1F"
        set recolor-darkcolor           "#7F8891"
        set recolor                     "true"

        set adjust-open width
      '';
    };
    "10-podcaster-config" = {
      "${tmpFilesHomeDir}/.config/podcaster" = dir;
      "${tmpFilesHomeDir}/.config/podcaster/philosophy_audio.yml" = link ''
        log: info
        parser:
          source: youtube
          cache_dir: /mnt/merged/podcaster_cache
          proxy: http://127.0.0.1:2080
          reversed: false
          # only_cache: true
        downloader:
          audio:
            bitrate: 0
            proxy: http://127.0.0.1:2080
            conversion:
              bitrate: 80
              samplerate: 44100
              stereo: false
          thumbnail:
            side_size: 200
            proxy: http://127.0.0.1:2080
        uploader:
          token: token
          proxy:
            ip: 127.0.0.1
            port: 2080
        tasks:
          - artist: "@nekrasovkalibrary"
            chat: "-1003870179768"
          - artist: "@WookashPodcast"
            chat: "-1002986588161"
          # - artist: "@NextW"
          #   chat: "-1002901199389"
          - artist: "@theoryaudiobooks9635"
            chat: "-1002510618083"
          - artist: "@Logaudiobooks"
            chat: "-1002510618083"
          - artist: "@Формальнаяфилософия"
            chat: "-1002744719988"
          - artist: "channel/UC3xY0O0R2zJ-v2tzreg1lLA"
            chat: "-1002311635950"
          - artist: "@achoufri"
            chat: "-1002345032355"
          - artist: "@onemorebrown"
            chat: "-1002090006695"
          - artist: "@SingularityasSublimity"
            chat: "-1002335077862"
          - artist: "@figmentsofthebrain"
            chat: "-1002084377197"
          - artist: "@reasonthrough5693"
            chat: "-1001692350005"
          - artist: "@centrefortime7469"
            chat: "-1002135483294"
          - artist: "@theory-of-justice"
            chat: "-1002243865337"
          - artist: "@PhilosophyBattle"
            chat: "-1002197139922"
          - artist: "@thinkbyzantine2101"
            chat: "-1002339225062"
          - artist: "@abrahamstone1415"
            chat: "-1002417557950"
          - artist: "@KaneB"
            chat: "@kane_b_audio"
          - artist: "@insolarancecult"
            chat: "@insolarance_cult"
          - artist: "@Stofflichkeit"
            chat: "-1002184446656"
          - artist: "@logicphilosophyandgodel2253"
            chat: "-1002148001728"
          - artist: "@davidbalcarras"
            chat: "-1002188264322"
          - artist: "@domloseva"
            chat: "-1002145537766"
          - artist: "@Philosophy_Overdose"
            chat: "@philosophy_overdose_podcaster"
          - artist: "@moscowcenterforconsciousne7974"
            chat: "@moscow_center_for_consciousness"
          - artist: "@gavagai2022"
            chat: "@gavagai2022"
          - artist: "@vozrozhru"
            chat: "@signummsk_audio"
          - artist: "@Derrunda"
            chat: "@derrunda_audio"
          - artist: "@dmitry_volkov"
            chat: "-1001818081814"
          - artist: "@PhilosophicalArchive"
            chat: "-1001869377939"
          - artist: "@PistisSophia"
            chat: "-1001968145753"
          - artist: "@philosophymsu"
            chat: "@philosophymsu"
          - artist: "@offphilosophy"
            chat: "@offphilosophy"
          - artist: "RoyIntPhilosophy"
            chat: "@royintphilosophy"
          - artist: "@deleuzephilosophy"
            chat: "@deleuzephilosophy"
          - artist: "@LSEPhilosophy"
            chat: "@LSEPhilosophy"
          - artist: "@profjeffreykaplan"
            chat: "@jeffreykaplan1"
          - artist: "@VictorGijsbers"
            chat: "-1002122249996"
          - artist: "@uAnalytiCon"
            chat: "-1002022420865"
          - artist: "@AntonioWolfphilosophy"
            chat: "-1001993318095"
          - artist: "@iph_ras"
            chat: "-1002144688163"
          - artist: "@nogre0"
            chat: "-1002067431404"
          - artist: "@MajestyofReason"
            chat: "-1002124736090"
          - artist: "@Friction"
            chat: "-1002089123403"
          - artist: "@ThePhilosophyChat"
            chat: "-1002014104487"
      '';
    };
    "10-scripts-config" = {
      "${tmpFilesHomeDir}/.config/scripts" = dir;
      "${tmpFilesHomeDir}/.config/scripts/rebuild-nixos-from-configuration.bash" = link ''
        #!/usr/bin/env bash

        sudo -s <<EOF
        export http_proxy="http://127.0.0.1:2080"
        export https_proxy="http://127.0.0.1:2080"
        nixos-rebuild switch --upgrade --max-jobs 16 --cores 16
        EOF
      '';
      "${tmpFilesHomeDir}/.config/scripts/alphabetically_sorted_images.fish" = link ''
        #!/usr/bin/env fish

        set cleaned_path (string unescape -- $argv[1])
        set -l search_pattern $argv[2]
        set -q search_pattern[1]; or set my_var "."
        fd --full-path "$argv[2]" "$cleaned_path" --type f | sort | nsxiv -a -
      '';
      "${tmpFilesHomeDir}/.config/scripts/newest_sorted_images.fish" = link ''
        #!/usr/bin/env fish

        set cleaned_path (string unescape -- $argv[1])
        set -l search_pattern $argv[2]
        set -q search_pattern[1]; or set my_var "."
        fd --full-path "$argv[2]" "$cleaned_path" --type f -X ls --full-time | sd '^([^ ]+ +){5}' \'\' | sort -r | sd '^[^/]+/' / | nsxiv -a -
      '';
      "${tmpFilesHomeDir}/.config/scripts/noise.fish" = link ''
        #!/usr/bin/env fish

        play -n synth brownnoise brownnoise channels 2
      '';
      "${tmpFilesHomeDir}/.config/scripts/nocolor.fish" = link ''
        #!/usr/bin/env fish

        sed 's/\x1B[@A-Z\\\]^_]\|\x1B\[[0-9:;<=>?]*[-!"#$%&'"'"'()*+,.\/]*[][\\@A-Z^_`a-z{|}~]//g'
      '';
      "${tmpFilesHomeDir}/.config/scripts/convert_to_avif_recursively.bash" = link ''
        #!/usr/bin/env bash

        set -o nounset

        ulimit -n `ulimit -Hn`

        # fd --type f -e png -e jpg -jpeg '.*' "$1" -x detox '{}'

        process_file() {
          file="$1"
          shift  # Remove the file argument, leaving only avifenc options
          output_file="''${file%.*}.avif"
          if [ ! -e "$output_file" ]; then
            avifenc -q 75 --speed 6 "$@" "$file" "$output_file" > /dev/null && rm "$file"
          else
            rm "$file"
          fi
        }
        export -f process_file

        # Collect additional arguments (everything after the first two required args)
        additional_args=()
        if [ $# -gt 2 ]; then
          additional_args=("''${@:3}")
        fi

        fd --type f -e png -e jpg -e jpeg '.*' "$1" | sort | parallel --jobs "$2" --bar process_file {} "''${additional_args[@]}"
      '';
      "${tmpFilesHomeDir}/.config/scripts/upscale.fish" = link ''
        #!/usr/bin/env fish

        cd $argv[1]
        fd . . --max-depth 1 --type f --extension png --extension jpg --extension jpeg --extension webp --exec mv {} batch

        if not fd --type f --extension png --extension jpg --extension jpeg --extension webp batch
            exit 0
        end

        srmd-ncnn-vulkan -i batch -o upscaled -s 3 -f png
        cd upscaled

        fd --type f --extension png --extension jpg --extension jpeg --exec sh -c 'avifenc -j all -q 75 --speed 6 "$0" "$\{0%.*}.avif"' {} \;
        cd ..
        rm -f batch/*
        mv upscaled/*.avif $argv[2]
        rm -f upscaled/*
      '';
      "${tmpFilesHomeDir}/.config/scripts/enumerate.fish" = link ''
        #!/usr/bin/env fish

        set folder $argv[1]

        set counter 1
        for file in $folder/*
            if test -f "$file"
                set ext (string split -r -m1 . -- $file)[2]
                set ext (if test -n "$ext"; echo ".$ext"; else; echo ""; end)
                set padded (printf "%03d" $counter)
                mv "$file" "$folder$padded$ext"
                set counter (math $counter + 1)
            end
        end
      '';
      "${tmpFilesHomeDir}/.config/scripts/urls_extract.bash" = link ''
        #!/usr/bin/env bash

        rg -oP "(http[^\"]+posts\\/\\w+)(:?_small)(\\.\\w+)" --replace '$1$3' < "$1"
      '';
      "${tmpFilesHomeDir}/.config/scripts/command_monitor.fish" = link ''
        #!/usr/bin/env fish

        set -l INTERVAL $argv[1]
        set -l COMMAND $argv[2..-1]

        while true
            clear
            eval $COMMAND
            sleep $INTERVAL
        end
      '';
      "${tmpFilesHomeDir}/.config/scripts/service_monitor.fish" = link ''
        #!/usr/bin/env fish

        set SERVICE_NAME $argv[1]
        set -q argv[2]; and set REFRESH_DELAY $argv[2]; or set REFRESH_DELAY 0.2

        watch -n $REFRESH_DELAY systemctl --user status $SERVICE_NAME.service $SERVICE_NAME.timer
      '';
      "${tmpFilesHomeDir}/.config/scripts/unzip_recursively.bash" = link ''
        #!/usr/bin/env bash

        # fd -e zip '.*' "$1" -x detox '{}'

        process_file() {
            file="$1"
            target="''${file%.*}"
            mkdir -p "$target"
            unzip -o -q "$file" -d "$target" && rm "$file"
        }
        export -f process_file

        fd -e zip '.*' "$1" | sort | parallel --bar --jobs "$2" process_file {}
      '';
      "${tmpFilesHomeDir}/.config/scripts/stop_all_ollama_llms.fish" = link ''
        #!/usr/bin/env fish

        ollama ps | awk 'NR>1 {print $1}' | xargs -L 1 -I {} ollama stop {}
      '';
      "${tmpFilesHomeDir}/.config/scripts/thumbnails_create.bash" = link ''
        #!/usr/bin/env bash

        set -o nounset
        # set -o errexit

        source_root="$1"
        target_root="$2"

        if [ ! -d "$source_root" ]; then
            echo "Error: Source directory '$source_root' does not exist."
            exit 1
        fi

        source_root=$(realpath "$source_root")
        target_root=$(realpath "$target_root")

        process_file() {
            local file="$1"
            local target_root="$2"

            local output_file="$target_root$file"

            local output_relative_dir=$(dirname "$file")
            mkdir -p "$target_root$output_relative_dir"

            ffmpeg -y -v quiet -i "$file" -vf "scale='if(gt(a,1),160,-1)':'if(gt(a,1),-1,160)'" "$output_file"
            touch -r "$file" "$output_file"
        }

        export -f process_file

        fd -t f -e avif . "$source_root" | while IFS= read -r file; do
            if [ ! -e "$target_root$file" ]; then
                echo "$file"
            fi
        done | sort | parallel --jobs "$3" --bar process_file {} "$target_root"
      '';
      "${tmpFilesHomeDir}/.config/scripts/rename_with_hash_values.bash" = link ''
        #!/usr/bin/env bash

        set -o nounset
        # set -o errexit

        source_root="$1"
        thumbnails_root="$2"

        if [ ! -d "$source_root" ]; then
            echo "Error: Source directory '$source_root' does not exist."
            exit 1
        fi

        source_root=$(realpath "$source_root")
        thumbnails_root=$(realpath "$thumbnails_root")

        process_file() {
            local file="$1"
            local thumbnails_root="$2"

            local file_dir=$(dirname "$file")
            local hash=$(xxhsum -H2 "$file" | cut -d' ' -f1 | head -c -1)
            local new_file="$file_dir/$hash.avif"

            if [[ "$file" != "$new_file" ]]; then
              local thumbnail="$thumbnails_root$file"
              local new_thumbnail="$thumbnails_root$new_file"

              mv "$file" "$new_file"
              mv "$thumbnail" "$new_thumbnail"

              touch -r "$new_file" "$new_thumbnail"
            fi
        }

        export -f process_file

        fd -t f -e avif . "$source_root" | parallel --bar --jobs "$3" process_file {} "$thumbnails_root"
      '';
      "${tmpFilesHomeDir}/.config/scripts/process_images.bash" = link ''
        #!/usr/bin/env bash

        set -o nounset

        images_root="$1"
        thumbnails_root="$2"

        convert_to_avif_recursively.bash "$images_root" 4
        thumbnails_create.bash "$images_root" "$thumbnails_root" 32
        rename_with_hash_values.bash "$images_root" "$thumbnails_root" 32
      '';
      "${tmpFilesHomeDir}/.config/scripts/download_from_urls_list.bash" = link ''
        #!/usr/bin/env bash

        set -o nounset

        url_file="$1"

        mapfile -t urls < "$url_file"

        download_one() {
            local url="$1"
            filename=$(basename "$url")
            if [ ! -e "$filename" ]; then
              curl -L -O -C - "$url" > /dev/null 2>&1
              return $?
            else
              return 0
            fi
        }
        export -f download_one

        parallel --bar --jobs "$2" download_one {} ::: "''${urls[@]}"
      '';
    };
    "10-waybar-config" = {
      "${tmpFilesHomeDir}/.config/waybar" = dir;
      "${tmpFilesHomeDir}/.config/waybar/config.jsonc" = link ''
        {
          "layer": "top",
          "position": "bottom",
          "autohide": true,
          "autohide-blocked": false,
          "exclusive": true,
          "passthrough": false,
          "gtk-layer-shell": true,
          "modules-left": [
            "disk#1",
            "disk#2",
          ],
          "modules-center": [
          ],
          "modules-right": [
            "pulseaudio",
            "cpu",
            "memory",
            "network#1",
            "network#2",
            "network#3",
            "clock",
          ],
          "clock": {
            "interval": 1,
            "timezone": "Europe/Moscow",
            "format": "{:%H:%M:%S %d.%m.%Y}",
          },
          "cpu": {
            "interval": 1,
            "format": " {usage:3}%",
          },
          "memory": {
            "interval": 1,
            "format": "  {used:5.2f}GB / {total:4.1f}GB",
          },
          "disk#1": {
            "interval": 1,
            "format": " {used:8} / {total:8}",
          },
          "disk#2": {
            "interval": 1,
            "format": " {used:8} / {total:7}",
            "path": "/mnt/merged"
          },
          "pulseaudio": {
            "format": "  {volume:3}%",
            "format-muted": " {volume:3}%",
          },
          "network#1": {
            "interval": 1,
            "format": " {bandwidthDownBytes}",
            "min-length": 11,
            "justify": "left"
          },
          "network#2": {
            "interval": 1,
            "format": " {bandwidthUpBytes}",
            "min-length": 11,
            "justify": "left"
          },
          "network#3": {
            "interval": 1,
            "format": "{ifname} {ipaddr}",
          },
        }
      '';
      "${tmpFilesHomeDir}/.config/waybar/style.css" = link ''
        @import "./colors.css";

        * {
          border: none;
          font-family: "JetbrainsMono Nerd Font";
          font-size: 18px;
        }
        window#waybar {
          background: rgba(0, 0, 0, 0.0);
        }

        #clock,
        #cpu,
        #memory,
        #disk.1,
        #disk.2,
        #pulseaudio,
        #network {
          color: black;
          margin-top: 4px;
          margin-bottom: 16px;
          padding-top: 6px;
          padding-bottom: 6px;
          padding-left: 10px;
          padding-right: 10px;
        }
        #disk.1,
        #pulseaudio {
          margin-left: 16px;
          padding-left: 15px;
          border-top-left-radius: 16px;
          border-bottom-left-radius: 16px;
        }
        #disk.2,
        #clock {
          margin-right: 16px;
          padding-right: 15px;
          border-top-right-radius: 16px;
          border-bottom-right-radius: 16px;
        }

        #disk.1 {
          background: linear-gradient(90deg, @color_1, @color_2);
        }
        #disk.2 {
          background: linear-gradient(90deg, @color_2, @color_3);
        }
        #pulseaudio {
          background: linear-gradient(90deg, @color_3, @color_4);
        }
        #cpu {
          background: linear-gradient(90deg, @color_4, @color_5);
        }
        #memory {
          background: linear-gradient(90deg, @color_5, @color_6);
        }
        #network.1 {
          background: linear-gradient(90deg, @color_6, @color_7);
        }
        #network.2 {
          background: linear-gradient(90deg, @color_7, @color_8);
        }
        #network.3 {
          background: linear-gradient(90deg, @color_8, @color_9);
        }
        #clock {
          background: linear-gradient(90deg, @color_9, @color_10);
        }
      '';
    };
  };
  services.navidrome = {
    enable = true;
    settings.MusicFolder = "/mnt/merged/music";
    settings.EnableSharing = true;
    openFirewall = true;
    settings = {
      Port = 4533;
      Address = "0.0.0.0";
    };
  };
  services.udev.packages = with pkgs; [
    via
    qmk-udev-rules
  ];
  systemd.user.services.podcaster = {
    description = "upload audio from youtube to telegram";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${tmpFilesHomeDir}/.local/bin/podcaster philosophy_audio";
      User = "mentalblood";
    };
    path = with pkgs; [
      yt-dlp
      ffmpeg
    ];
    wantedBy = [ "default.target" ];
  };
  systemd.user.timers.podcaster = {
    description = "run podcaster every 2 hours";
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "2h";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
    enable = true;
  };
  programs.fish = {
    enable = true;
    generateCompletions = false;
  };
  programs.niri.enable = true;
  programs.xwayland.enable = true;
  programs.steam.enable = true;
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox = {
        executable = "${pkgs.firefox}/bin/firefox";
        profile = "${pkgs.firejail}/etc/firejail/firefox.profile";
        extraArgs = [
          "--private=/mnt/merged/jails/firefox"
        ];
      };
      steam = {
        executable = "${pkgs.steam}/bin/steam";
        profile = "${pkgs.firejail}/etc/firejail/steam.profile";
        extraArgs = [
          "--private=~/jails/steam"
        ];
      };
      ollama = {
        executable = "${pkgs.ollama-rocm}/bin/ollama";
        extraArgs = [
          "--private=/mnt/merged/jails/ollama"
          "--net=ollama_net"
          "--ip=10.0.0.2"
        ];
      };
      ollama-with-internet-access = {
        executable = "${ollama-wrapper-script}/bin/ollama-wrapper-script";
        extraArgs = [
          "--private=/mnt/merged/jails/ollama_with_internet_access"
        ];
      };
      hf = {
        executable = "${pkgs.python3Packages.huggingface-hub}/bin/hf";
        extraArgs = [
          "--private=/mnt/merged/jails/huggingface-hub"
        ];
      };
      tuna = {
        executable = "/usr/bin/tuna";
        extraArgs = [
          "--private=/mnt/merged/jails/tuna"
        ];
      };
    };
  };
  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" ];
    policies = {
      PasswordManagerEnabled = false;
      Proxy = {
        Mode = "manual";
        HTTPProxy = "127.0.0.1:2080";
        SSLProxy = "127.0.0.1:2080";
        NoProxy = "www.reddit.com";
      };
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "never";
      SearchBar = "unified";
      ExtensionSettings = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "tridactyl.vim@cmcaine.co.uk" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
          installation_mode = "force_installed";
        };
      };
      Preferences = {
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.formfill.enable" = lock-false;
        "browser.search.suggest.enabled" = lock-false;
        "browser.search.suggest.enabled.private" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
      };
    };
  };
  fileSystems = {
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" ];
    };
    "/mnt/base1" = {
      device = "/dev/disk/by-uuid/1c2cb4f3-9365-4b75-97e7-e0cc1201d123";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/base2" = {
      device = "/dev/disk/by-uuid/8608541a-47da-4c91-99b3-8bca80b6e35a";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/base3" = {
      device = "/dev/disk/by-uuid/4c228291-82a2-4336-a433-5c16afa8a9a0";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/base4" = {
      device = "/dev/disk/by-uuid/c0045f59-760f-4238-a0ff-0b09639240d5";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/base5" = {
      device = "/dev/disk/by-uuid/39b0e09d-1d54-46c5-a04d-f932ad036505";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/base6" = {
      device = "/dev/disk/by-uuid/a04cce22-911b-4385-9a6c-dcbee2254ad6";
      fsType = "ext4";
      options = [ "defaults" ];
    };
    "/mnt/merged" = {
      device = "/mnt/base*";
      fsType = "mergerfs";
      options = [
        "defaults"
        "allow_other"
        "minfreespace=1G"
        "category.create=mfs"
      ];
      depends = [
        "/mnt/base1"
        "/mnt/base2"
        "/mnt/base3"
        "/mnt/base4"
        "/mnt/base5"
        "/mnt/base6"
      ];
    };
  };
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    helix
    waybar
    duf
    dust
    mergerfs
    mergerfs-tools
    alacritty
    fuzzel
    crystal
    shards
    pulseaudio
    pulsemixer
    cmus
    zathura
    throne
    bottom
    gh
    git
    mpv
    bluetui
    warpinator
    yazi
    qbittorrent
    nixfmt
    rust-analyzer
    rustup
    fish-lsp
    vscode-langservers-extracted
    markdown-oxide
    nixd
    taplo
    tmux
    ffmpeg
    yt-dlp
    sd
    gcc
    awww
    imagemagick
    fd
    ripgrep
    detox
    chromium
    xwayland-satellite
    parallel
    unzip
    dioxus-cli
    libavif
    playerctl
    ollama-rocm
    iptables
    python3Packages.huggingface-hub
    bash-language-server
    wine
    _7zz
    graphviz
    dot-language-server
    via
    vial
    cloudflared
    feishin
    easytag
    syncthing
    hyperfine
    xxhash
    (pkgs.symlinkJoin {
      name = "nsxiv";
      paths = [ pkgs.nsxiv ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/nsxiv \
          --run 'export XDG_CACHE_HOME="/mnt/merged/.cache/"'
      '';
    })
  ];
  fonts.packages = with pkgs; [
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono
  ];
  system.stateVersion = "25.11";
}
