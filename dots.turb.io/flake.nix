{
  description = "A lil server to talk to my flip dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        flippyflops = pkgs.callPackage ./default.nix { };
      in
      {
        defaultPackage = flippyflops;
        packages.flippyflops = flippyflops;
      });
}
