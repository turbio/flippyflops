with (import <nixpkgs> { });
rec {
  flippyflops = mkYarnPackage {
    name = "flippyflops";
    src = ./.;
    packageJSON = ./package.json;
    yarnLock = ./yarn.lock;
    yarnNix = ./yarn.nix;
  };
}
