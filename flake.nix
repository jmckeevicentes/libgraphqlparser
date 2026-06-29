{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };
  };

  outputs = {self, nixpkgs }:  
    let 
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };

      nixPackagesCross = pkgs.pkgsCross.mingwW64;

      pythonEnv = pkgs.python3.withPackages (p: with p; [
        ctypesgen
      ]);

      libgraphqlparser-w64 = nixPackagesCross.stdenv.mkDerivation {
        pname = "libgraphqlparser";
        version = "master";
        src = builtins.path {
          path = ./.;
          name = "libgraphqlparser-src";
        };
        nativeBuildInputs = with nixPackagesCross.buildPackages; [
          clang
          cmake
          pythonEnv
          bison
          flex
          pkg-config-unwrapped
        ];
        unpackPhase = "";
        buildPhase = ''
          cmake .
          make
        '';
        installPhase = ''
          make install
        '';
        };

      libgraphqlparser = (with pkgs; stdenv.mkDerivation {
        pname = "libgraphqlparser";
        version = "master";
        src = builtins.path {
          path = ./.;
          name = "libgraphql-src";
        };
        nativeBuildInputs = [
          clang
          cmake
          pythonEnv
          bison
          flex
          pkg-config-unwrapped
          patchelf
        ];
        buildPhase = ''
          cmake .
          make 
        '';
        installPhase = ''
          make install
        '';
      });

      libgraphqlparser-dump_json_ast = (with pkgs; stdenv.mkDerivation {
        pname = "dump_json_ast";
        version = "master";
        src = builtins.path {
          path = ./.;
          name = "libgraphql-src";
        };
        nativeBuildInputs = [
          clang
          cmake
          pythonEnv
          bison
          flex
          pkg-config-unwrapped
          patchelf
        ];
        buildInputs = [
          self.packages."x86_64-linux".libgraphqlparser
        ];
        buildPhase = ''
          cmake -DSKIP_CMAKE_BUILD_RPATH=ON .
          make dump_json_ast
        '';
        installPhase = ''
          mkdir -p $out/bin
          cp dump_json_ast $out/bin
          patchelf --shrink-rpath --allowed-rpath-prefixes /nix/store $out/bin/dump_json_ast
          patchelf --add-rpath ${self.packages."x86_64-linux".libgraphqlparser}/lib $out/bin/dump_json_ast
        '';
      });

      forAllSystems = function: 
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});

    in rec {

      packages = forAllSystems (pkgs: {
        default = libgraphqlparser;
        libgraphqlparser = libgraphqlparser;
        libgraphqlparser-w64 = libgraphqlparser-w64;
        libgraphqlparser-dump_json_ast = libgraphqlparser-dump_json_ast;
      });

    }; 
}
