{
  imports = [
    ./hardware.nix
    ./syncthing_base.nix
  ];

  boot = {
    useSystemdBoot = true;
    default = true;
  };

  networking = {
    networkmanager.enable = true;
    hostId = "9b68eb32";
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  sound.enable = true;

  services = {
    autopull.enable = false;

    displayManager.sddm.enable = true;

    xserver = {
      enable = true;
      desktopManager.plasma5.enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    syncthing.settings.folders = {
      "notes" = {
        id = "l62ul-lpweo"; # cspell:disable-line
        path = "/home/richie/notes";
        devices = [
          "phone"
          "jeeves"
        ];
        fsWatcherEnabled = true;
      };
      "books" = {
        id = "6uppx-vadmy"; # cspell:disable-line
        path = "/home/richie/books";
        devices = [
          "phone"
          "jeeves"
        ];
        fsWatcherEnabled = true;
      };
      "important" = {
        id = "4ckma-gtshs"; # cspell:disable-line
        path = "/home/richie/important";
        devices = [
          "phone"
          "jeeves"
        ];
        fsWatcherEnabled = true;
      };
      "music" = {
        id = "vprc5-3azqc"; # cspell:disable-line
        path = "/home/richie/music";
        devices = [
          "phone"
          "jeeves"
        ];
        "projects" = {
          id = "vyma6-lqqrz"; # cspell:disable-line
          path = "/home/richie/projects";
          devices = [ "jeeves" ];
          fsWatcherEnabled = true;
        };
        fsWatcherEnabled = true;
      };
    };

    zerotierone = {
      enable = true;
      joinNetworks = [ "e4da7455b2ae64ca" ];
    };
  };

  services = {
    mongodb = {
      enable = true;
    };
    elasticsearch = {
      enable = true;
    };
    graylog = {
      enable = true;
      passwordSecret = "LfjRKrrbONYDCvfD8gCNYqMzVAPHrxVBaw1oR3zIE73cF0EUaj8yEU4DsY8ADbwlGKCt0f2Q9Di8CN6JCYqGug2cfUwE9oNG";
      rootPasswordSha2 = "e3c652f0ba0b4801205814f8b6bc49672c4c74e25b497770bb89b22cdeb4e951";
      elasticsearchHosts = [ "http://localhost:9200" ];
    };
  };
  system.autoUpgrade.enable = false;
  system.stateVersion = "23.11";
}
