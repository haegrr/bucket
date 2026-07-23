{
  self',
  pkgs,
  ...
}:

{
  projectRootFile = "flake.nix";
  programs.nixfmt.enable = true;

  settings.formatter.scoop =
    let
      formatter = pkgs.writeShellApplication {
        name = "scoop-formatter";
        runtimeInputs = [
          self'.packages.formatjson
          pkgs.dos2unix
        ];
        text = ''
          for f in "$@"; do
            formatjson "$(basename "$f" .json)"
            unix2dos "$f"
          done
        '';
      };
    in
    {
      command = "${formatter}/bin/scoop-formatter";
      includes = [ "bucket/*.json" ];
    };
}
