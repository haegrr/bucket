{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-hooks.url = "github:cachix/git-hooks.nix";
    git-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }@inputs:
    with nixpkgs.lib;
    let
      mkTransposed = system: flake: genAttrs [ "packages" "lib" ] (attr: flake.${attr}.${system});
      eachSystem =
        f:
        genAttrs systems.flakeExposed (
          system:
          f {
            pkgs = nixpkgs.legacyPackages.${system};
            self' = mkTransposed system self;
            inputs' = mapAttrs (_: mkTransposed system) inputs;
            inherit system;
          }
        );
      treefmtEval = eachSystem (
        {
          pkgs,
          self',
          inputs',
          ...
        }:
        treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];

          _module.args = {
            inherit self' inputs';
          };
        }
      );
    in
    {
      packages = eachSystem (
        { pkgs, ... }:
        let
          scoop = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            pname = "scoop";
            version = "0.5.3";

            src = pkgs.fetchFromGitHub {
              owner = "ScoopInstaller";
              repo = "Scoop";
              rev = "v${finalAttrs.version}";
              hash = "sha256-3/fU4UGou2n4wBhj9gqRDrmdbzMd9pWuNn2gZbeCF/0=";
            };

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/share"
              cp -R . "$out/share/scoop"

              runHook postInstall
            '';
          });
        in
        {
          bucket = pkgs.stdenvNoCC.mkDerivation {
            name = "bucket";

            src = self;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/bin" "$out/share"

              for script in bin/*.ps1; do
                name="$(basename "$script" .ps1)"
                outscript="$out/share/$name.ps1"
                cp "$script" "$outscript"
                makeWrapper ${pkgs.powershell}/bin/pwsh "$out/bin/$name" \
                  --set SCOOP_HOME "${scoop}/share/scoop" \
                  --add-flags "-NoLogo -NoProfile -File \"$outscript\""
              done

              runHook postInstall
            '';
          };
        }
      );

      apps = eachSystem (
        { self', ... }:
        genAttrs [ "checkurls" "checkver" "formatjson" "missing-checkver" ] (name: {
          type = "app";
          program = getExe' self'.packages.bucket name;
        })
      );

      devShells = eachSystem (
        {
          pkgs,
          inputs',
          system,
          ...
        }:
        let
          commitHook = inputs'.git-hooks.lib.run {
            src = self;
            hooks = {
              treefmt = {
                enable = true;
                package = treefmtEval.${system}.config.build.wrapper;
              };
            };
          };
        in
        {
          default = pkgs.mkShell {
            inherit (commitHook) shellHook;
            buildInputs = commitHook.enabledPackages;
          };
        }
      );

      formatter = eachSystem ({ system, ... }: treefmtEval.${system}.config.build.wrapper);

      checks = eachSystem (
        { system, ... }: {
          formatting = treefmtEval.${system}.config.build.check self;
        }
      );
    };
}
