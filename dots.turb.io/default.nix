{ pkgs ? (import <nixpkgs> { }) }:
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
pkgs.writeShellScriptBin "flippyflops" ''
  cd ${./.} && ${yarnedPkg}/bin/flippyflops
''
