{
  description = "Build environment for SlimeVR-Installer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "slimevr-installer";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.nsis ];

          buildPhase = ''
            makensis windows/web/slimevr_web_installer.nsi
          '';

          installPhase = ''
            mkdir -p $out
            cp windows/web/slimevr_web_installer.exe $out/
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ 
            nsis
            wineWow64Packages.stable
          ];

          shellHook = ''
            echo "SlimeVR Installer Dev Shell"
            echo "Run 'makensis <file>.nsi' to compile manually."
          '';
        };
      });
}