{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    with nixpkgs.lib;
    let
      eachSystem =
        f:
        genAttrs systems.flakeExposed (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            inherit system;
          }
        );
      treefmtEval = eachSystem (
        { pkgs, system, ... }:
        treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];

          _module.args.self'.packages = self.packages.${system};
        }
      );
    in
    {
      packages = eachSystem (
        { pkgs, ... }:
        let
          scriptNames = [
            "checkurls"
            "checkver"
            "formatjson"
            "missing-checkver"
          ];

          scoop = pkgs.stdenvNoCC.mkDerivation {
            pname = "scoop";
            version = "0.5.3";

            src = pkgs.fetchFromGitHub {
              owner = "ScoopInstaller";
              repo = "Scoop";
              rev = "v0.5.3";
              hash = "sha256-3/fU4UGou2n4wBhj9gqRDrmdbzMd9pWuNn2gZbeCF/0=";
            };

            dontBuild = true;

            installPhase = ''
              runHook preInstall
              mkdir -p "$out/share"
              cp -R . "$out/share/scoop"
              runHook postInstall
            '';
          };

          wrapScript =
            name:
            pkgs.runCommandLocal name
              {
                script = ./bin/${name}.ps1;
                nativeBuildInputs = [ pkgs.makeWrapper ];
              }
              ''
                mkdir -p "$out/bin" "$out/share"
                outscript="$out/share/${name}.ps1" 
                cp "$script" "$outscript"
                makeWrapper ${pkgs.powershell}/bin/pwsh "$out/bin/${name}" \
                  --set SCOOP_HOME "${scoop}/share/scoop" \
                  --add-flags "-NoLogo -NoProfile -File \"$outscript\""
              '';
        in
        genAttrs scriptNames wrapScript
      );

      formatter = eachSystem ({ system, ... }: treefmtEval.${system}.config.build.wrapper);
      checks = eachSystem (
        { system, ... }: {
          formatting = treefmtEval.${system}.config.build.check self;
        }
      );
    };
}
