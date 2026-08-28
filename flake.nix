{
  description = "fastapi: version-bumped ahead of nixpkgs through a Python package overlay.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version hash;
      source = { type = "pypi"; pname = "fastapi"; format = "sdist"; };
      overlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            fastapi = pyprev.fastapi.overridePythonAttrs (_: {
              inherit version;
              doCheck = false;
              src = pyfinal.fetchPypi { inherit version hash; pname = "fastapi"; };
            });
          })
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            fastapi = pkgs.python3.pkgs.fastapi;
            default = pkgs.python3.pkgs.fastapi;
            update-version = flake-lib.lib.mkUpdateVersion { inherit pkgs source; buildAttr = "fastapi"; };
            update-branches = flake-lib.lib.mkUpdateBranches { inherit pkgs source; pinSchema = "pypi"; };
          };
        }) // {
      overlays.default = overlay;
    };
}
