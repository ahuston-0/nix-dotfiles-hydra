{
  nixpkgs,
  pulls,
  branches,

  ...
}:
let
  pkgs = import nixpkgs { };

  makeSpec =
    contents:
    builtins.derivation {
      name = "spec.json";
      system = "x86_64-linux";
      preferLocalBuild = true;
      allowSubstitutes = false;
      builder = "/bin/sh";
      args = [
        (builtins.toFile "builder.sh" ''
          echo "$contents" > $out
        '')
      ];
      contents = builtins.toJSON contents;
    };

  prs = builtins.fromJSON (builtins.readFile pulls);
  refs = builtins.fromJSON (builtins.readFile branches);
  repo = "ahuston-0/nix-dotfiles-hydra";

  makeJob =
    {
      schedulingshares ? 10,
      keepnr ? 3,
      description,
      flake,
    }:
    {
      inherit
        description
        flake
        schedulingshares
        keepnr
        ;
      enabled = 1;
      type = 1;
      hidden = false;
      checkinterval = 300; # every 6 months
      enableemail = false;
      emailoverride = "";
    };
  jobOfRef =
    name:
    { ref, ... }:
    if isNull (builtins.match "^refs/heads/(.*)$" builtins.trace ref) then
      null
    else
      {
        name = "branch-${name}";
        value = makeJob {
          description = "Branch ${name}";
          flake = "git+ssh://git@github.com/${repo}?ref=${ref}";
        };
      };
  jobOfPR = id: info: {
    name = "pr-${id}";
    value = makeJob {
      description = "PR ${id}: ${info.${id}.title}";
      flake = "git+ssh://git@github.com/${info.${id}.head.repo.full_name}?ref=${info.${id}.head.ref}";
    };
  };
  attrsToList = l: builtins.attrValues (builtins.mapAttrs (name: value: { inherit name value; }) l);
  readJSONFile = f: builtins.fromJSON (builtins.readFile f);
  mapFilter = f: l: builtins.filter (x: !(isNull x)) (map f l);
in
# throwJSON = x: throw (builtins.toJSON x);
# prJobsets = pkgs.lib.mapAttrs (num: info: {
#   enabled = 1;
#   hidden = false;
#   description = "PR ${num}: ${info.title}";
#   checkinterval = 60;
#   schedulingshares = 20;
#   enableemail = false;
#   emailoverride = "";
#   keepnr = 1;
#   type = 1;
#   flake = "github:ahuston-0/nix-dotfiles-hydra/pull/${num}/head";
# }) prs;
# branchJobsets = pkgs.lib.mapAttrs (num: info: {
#   enabled = 1;
#   hidden = false;
#   description = "PR ${num}: ${info.title}";
#   checkinterval = 60;
#   schedulingshares = 20;
#   enableemail = false;
#   emailoverride = "";
#   keepnr = 1;
#   type = 1;
#   flake = "github:ahuston-0/nix-dotfiles-hydra/pull/${num}/head";
# }) branches;
# updateJobsets = pkgs.lib.mapAttrs (num: info: {
#   enabled = 1;
#   hidden = false;
#   description = "PR ${num}: ${info.title}";
#   checkinterval = 60;
#   schedulingshares = 20;
#   enableemail = false;
#   emailoverride = "";
#   keepnr = 1;
#   type = 1;
#   flake = "github:ahuston-0/nix-dotfiles-hydra/pull/${num}/head";
# }) prs;
# mkFlakeJobset = branch: {
#   description = "Build ${branch}";
#   checkinterval = "3600";
#   enabled = "1";
#   schedulingshares = 100;
#   enableemail = false;
#   emailoverride = "";
#   keepnr = 3;
#   hidden = false;
#   type = 1;
#   flake = "github:ahuston-0/nix-dotfiles-hydra/tree/${branch}";
# };
# desc = prJobsets // {
#   "main" = mkFlakeJobset "main";
#   "feature-upsync" = mkFlakeJobset "feature/upsync";
# };
# log = {
#   pulls = prs;
#   jobsets = desc;
# };
{
  # jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
  #   cat >$out <<EOF
  #   ${builtins.toJSON desc}
  #   EOF
  #   # This is to get nice .jobsets build logs on Hydra
  #   cat >tmp <<EOF
  #   ${builtins.toJSON log}
  #   EOF
  #   ${pkgs.jq}/bin/jq . tmp
  # '';
  jobsets = makeSpec (
    builtins.listToAttrs (map ({ name, value }: jobOfPR name value) (attrsToList (readJSONFile prs)))
    // builtins.listToAttrs (
      mapFilter ({ name, value }: jobOfRef name value) (attrsToList (readJSONFile refs))
    )
    // {
      main = makeJob {
        description = "main";
        flake = "github:${repo}";
        keepnr = 10;
        schedulingshares = 100;
      };
    }
  );
}
