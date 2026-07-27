{
  self',
  pkgs,
  lib,
  ...
}:

with lib;

{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;

  settings.formatter.scoop =
    let
      formatter = pkgs.writeShellApplication {
        name = "scoop-formatter";
        runtimeInputs = [
          self'.packages.bucket
          pkgs.dos2unix
        ];
        text = ''
          backupdir="$(mktemp -d)/"
          trap 'rm -rf -- "$backupdir"' EXIT

          for f in "$@"; do
            backup="$backupdir/$(basename "$f")"
            cp -a "$f" "$backup"
            formatjson "$(basename "$f" .json)"
            unix2dos "$f"
            
            if cmp -s "$f" "$backup"; then
              cp -a "$backup" "$f"
            fi
          done
        '';
      };
    in
    {
      command = getExe' formatter "scoop-formatter";
      includes = [ "bucket/*.json" ];
    };
}
