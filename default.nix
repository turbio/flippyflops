{ pkgs ? (import <nixpkgs> { }), port ? 3000, host ? "0.0.0.0" }:
let
  yarnedPkg = pkgs.mkYarnPackage
    {
      name = "flippyflops";
      src = ./.;
      packageJSON = ./package.json;
      yarnLock = ./yarn.lock;
      yarnNix = ./yarn.nix;
    };
in

pkgs.writeShellScriptBin "flippyflops" "PORT=${toString port} HOST=${host} ${yarnedPkg}/bin/flippyflops"
