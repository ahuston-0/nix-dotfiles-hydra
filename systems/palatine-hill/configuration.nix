{ config, pkgs, ... }:
let
  keygen = key: {
    "${key}" = {
      format = "binary";
      sopsFile = ./keys/${key};
      mode = "0400";
      path = "/crypto/keys/${key}";
    };
  };
in
{

  systemd.services.hydra-notify.serviceConfig.EnvironmentFile =
    config.sops.secrets."hydra/environment".path;
  programs.git.lfs.enable = false;
  networking = {
    hostId = "dc2f9781";
    firewall.enable = false;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  boot = {
    zfs.extraPools = [ "ZFS-primary" ];
    loader.grub.device = "/dev/sda";
    filesystem = "zfs";
    useSystemdBoot = true;
    kernelParams = [
      "i915.force_probe=56a5"
      "i915.enable_guc=2"
    ];
    kernel.sysctl = {
      "vm.overcommit_memory" = 1;
      "vm.swappiness" = 10;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  nix = {
    extraOptions = ''
      allowed-uris = github: gitlab: git+https:// git+ssh:// https://
      builders-use-substitutes = true
    '';

    buildMachines = [
      {
        hostName = "localhost";
        maxJobs = 2;
        protocol = "ssh-ng";
        speedFactor = 2;
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "i686-linux"
        ];

        supportedFeatures = [
          "kvm"
          "nixos-test"
          "big-parallel"
          "benchmark"
        ];
      }
    ];
  };

  hardware = {
    enableAllFirmware = true;
    opengl = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime
        intel-media-sdk
      ];
    };
  };

  virtualisation.docker.daemon.settings.data-root = "/var/lib/docker2";

  environment.systemPackages = with pkgs; [
    attic-client
    attic
    docker-compose
    jellyfin-ffmpeg
  ];

  services = {
    samba.enable = true;
    nfs.server.enable = true;
    openssh.ports = [ 666 ];
    smartd.enable = true;
    zfs = {
      trim.enable = true;
      autoScrub.enable = true;
    };

    postgresql = {
      enable = true;
      enableJIT = true;
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      alice  postgres
           # Let other names login as themselves
           superuser_map      /^(.*)$   \1
      '';

      ensureDatabases = [ "atticd" ];
      ensureUsers = [
        {
          name = "atticd";
          ensureDBOwnership = true;
        }
      ];

      # initialScript = config.sops.secrets."postgres/init".path;

      upgrade = {
        enable = true;
        stopServices = [
          "hydra-evaluator"
          "hydra-init"
          "hydra-notify"
          "hydra-queue-runner"
          "hydra-send-stats"
          "hydra-server"
          "atticd"
        ];
      };
    };

    hydra = {
      enable = true;
      hydraURL = "http://localhost:3000";
      smtpHost = "alicehuston.xyz";
      notificationSender = "hydra@alicehuston.xyz";
      gcRootsDir = "/ZFS/ZFS-primary/hydra";
      useSubstitutes = true;
      buildMachinesFiles = [ ];
      minimumDiskFree = 50;
      minimumDiskFreeEvaluator = 100;
    };

    nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets."nix-serve/secret-key".path;
    };
    atticd = {
      enable = true;

      credentialsFile = config.sops.secrets."attic/secret-key".path;

      settings = {
        listen = "[::]:8183";
        allowed-hosts = [ "attic.alicehuston.xyz" ];
        api-endpoint = "https://attic.alicehuston.xyz";
        compression.type = "none"; # let ZFS do the compressing
        database = {
          url = "postgres://atticd?host=/run/postgresql";
          # disable postgres, using SOPS fails at below :(
          # https://github.com/zhaofengli/attic/blob/main/nixos/atticd.nix#L57
          # url = "sqlite:///ZFS/ZFS-primary/attic/server.db?mode=rwc";
          heartbeat = true;
        };
        storage = {
          type = "local";
          path = "/ZFS/ZFS-primary/attic/storage";
        };

        # Warning: If you change any of the values here, it will be
        # difficult to reuse existing chunks for newly-uploaded NARs
        # since the cutpoints will be different. As a result, the
        # deduplication ratio will suffer for a while after the change.
        chunking = {
          # The minimum NAR size to trigger chunking
          #
          # If 0, chunking is disabled entirely for newly-uploaded NARs.
          # If 1, all NARs are chunked.
          nar-size-threshold = 64 * 1024; # 64 KiB

          # The preferred minimum size of a chunk, in bytes
          min-size = 16 * 1024; # 16 KiB

          # The preferred average size of a chunk, in bytes
          avg-size = 64 * 1024; # 64 KiB

          # The preferred maximum size of a chunk, in bytes
          max-size = 256 * 1024; # 256 KiB
        };
      };
    };
  };

  # borrowing from https://github.com/Shawn8901/nix-configuration/blob/4b8d1d44f47aec60feb58ca7b7ab5ed000506e90/modules/nixos/private/hydra.nix
  # configured default webstore for this on root user separately
  systemd.services.attic-watch-store = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    description = "Upload all store content to binary catch";
    serviceConfig = {
      User = "root";
      Restart = "always";
      ExecStart = "${pkgs.attic}/bin/attic watch-store cache-nix-dot";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/E/y4UJQid6/0D9babh8l/3jTDJRXqZQ5rPcoxwm1j root@palatine-hill"
  ];

  users.users.hydra-queue-runner.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/E/y4UJQid6/0D9babh8l/3jTDJRXqZQ5rPcoxwm1j root@palatine-hill"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINHtwvfXg/QFjMAjC4JRjlMAaGPgEfSyhpprNpqbGSJn hydra-queue-runner@palatine-hill"
  ];

  system.autoUpgrade.flake = "github:ahuston-0/nix-dotfiles-hydra";

  gc.options = "--delete-older-than 150d";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets =
      {
        "hydra/environment".owner = "hydra";
        "nix-serve/secret-key".owner = "root";
        "attic/secret-key".owner = "root";
        "attic/database-url".owner = "root";
        "postgres/init".owner = "postgres";
      }
      // keygen "zfs-attic-key"
      // keygen "zfs-backup-key"
      // keygen "zfs-calibre-key"
      // keygen "zfs-db-key"
      // keygen "zfs-docker-key"
      // keygen "zfs-games-key"
      // keygen "zfs-hydra-key"
      // keygen "zfs-libvirt-key"
      // keygen "zfs-main-key"
      // keygen "zfs-nxtcld-key"
      // keygen "zfs-torr-key"
      // keygen "zfs-var-docker-key";
  };

  system.stateVersion = "23.05";
}
