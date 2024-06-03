{ inputs, outputs }:
let
  inherit (inputs.nixpkgs.lib) mapAttrs;

  getCfg = _: cfg: cfg.config.system.build.toplevel;
  getFormat =
    _: cfg: format:
    cfg.config.formats.${format};
  imageWrapper = format: mapAttrs getFormat outputs.nixosConfigurations format;
in
{
  inherit (outputs) formatter devShells;
  hosts = mapAttrs getCfg outputs.nixosConfigurations;
  install-isos = imageWrapper "install-iso";
  isos = imageWrapper "iso";
  qcow = imageWrapper "qcow";
}
