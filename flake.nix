{
  description = "Development shell for the rails-pretty-logger Rails engine";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          playwright = pkgs.writeShellScriptBin "playwright" ''
            exec ${pkgs.nodejs}/bin/node ${pkgs.playwright-driver}/cli.js "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.gcc
              pkgs.libyaml.dev
              pkgs.nodejs
              pkgs.pkg-config
              pkgs.ruby_3_3
              pkgs.playwright-driver.browsers
              playwright
            ];

            shellHook = ''
              export BUNDLE_GEMFILE="$PWD/Gemfile"
              export BUNDLE_PATH="$PWD/vendor/bundle"
              export BUNDLE_BIN="$PWD/.bundle/bin"
              export PKG_CONFIG_PATH="${pkgs.libyaml.dev}/lib/pkgconfig''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
              export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
              export PLAYWRIGHT_CLI_EXECUTABLE_PATH="${playwright}/bin/playwright"
            '';
          };
        });
    };
}
