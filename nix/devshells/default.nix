{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.treefmt.overrideAttrs (old: {
  GOROOT = "${old.go}/share/go";

  shellHook = ''
    # this is only needed for hermetic builds
    unset GO_NO_VENDOR_CHECKS GOSUMDB GOPROXY GOFLAGS
  '';

  nativeBuildInputs =
    old.nativeBuildInputs
    ++ [
      pkgs.goreleaser
      pkgs.golangci-lint
      pkgs.delve
      pkgs.pprof
      pkgs.graphviz
      pkgs.nodejs
    ]
    ++
    # include formatters for development and testing
    (import ../packages/treefmt/formatters.nix pkgs)
    # docs related helpers
    ++ (let
      docs = command:
        pkgs.writeShellApplication {
          name = "docs:${command}";
          runtimeInputs = [pkgs.nodejs];
          text = ''cd "''${DIRENV_DIR:1}/docs" && npm ci && npm run ${command}'';
        };
    in [
      (docs "dev")
      (docs "build")
      (docs "preview")
      (pkgs.writeShellApplication {
        name = "vhs";
        runtimeInputs =
          [
            perSystem.self.treefmt
            pkgs.rsync
            pkgs.vhs
          ]
          ++ (import ../packages/treefmt/formatters.nix pkgs);
        text = ''vhs "$@"'';
      })
    ]);
})
