{
  description = "specialists-fi.github.io generator";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.neoathame.url = "github:infinitivewitch/neoathame";
  inputs.neoathame.flake = false;

  outputs = { self, nixpkgs, ... }@inputs:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      inherit (pkgs) lib;
    in
    {
      packages."x86_64-linux".pages = pkgs.stdenv.mkDerivation {
        pname = "specialists-fi-pages";
        version = "2023-06-27";
        src = ./.;
        nativeBuildInputs = [
          pkgs.zola
        ];
        configurePhase = ''
          mkdir -p themes/
          ln -s ${inputs.neoathame} themes/neoathame
        '';
        buildPhase = ''
          zola build
        '';
        installPhase = ''
          cp -rf public $out
        '';
      };
      packages."x86_64-linux".serve = pkgs.writeScriptBin "specialists-fi-serve" ''
        read FLAKE_ROOT < <(
          ${lib.getExe pkgs.nix} flake metadata --json | ${lib.getExe pkgs.jq} .locked.url --raw-output
        )
        FLAKE_ROOT=''${FLAKE_ROOT#file://}

        if [[ -d themes/neoathame ]] ; then
          true
        else
          mkdir -p themes/
          ln -s ${inputs.neoathame} themes/neoathame
        fi

        ${pkgs.zola}/bin/zola -r "$FLAKE_ROOT" serve
      '';
      packages."x86_64-linux".default = self.packages."x86_64-linux"."pages";

      apps."x86_64-linux".serve = {
        type = "app";
        program = "${self.packages.x86_64-linux.serve}/bin/specialists-fi-serve";
      };
      apps."x86_64-linux".default = self.apps."x86_64-linux".serve;
    };
}
