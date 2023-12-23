{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bat
    btop
    deadnix
    direnv
    fd
    file
    htop
    jp2a
    jq
    lsof
    neofetch
    nix-init
    nix-output-monitor
    nix-prefetch
    nix-tree
    nixpkgs-fmt
    nmap
    pciutils
    python3
    qrencode
    ripgrep
    speedtest-cli
    tig
    tokei
    tree
    unzip
    ventoy
    wget
    zoxide
    zsh-nix-shell
  ];
}