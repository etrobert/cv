{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, self }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            tex = pkgs.texlive.combine {
              inherit (pkgs.texlive)
                scheme-basic
                geometry
                hyperref
                enumitem
                titlesec
                parskip
                ec
                cm-super
                latexindent
                ;
            };
          in
          f pkgs tex
        );
    in
    {
      packages = forAllSystems (
        pkgs: tex: {
          default = pkgs.stdenvNoCC.mkDerivation {
            name = "cv";
            src = ./.;
            buildInputs = [ tex ];
            buildPhase = "pdflatex cv.tex";
            installPhase = "install -Dm644 cv.pdf $out/cv.pdf";
          };
        }
      );

      apps = forAllSystems (
        pkgs: tex: {
          default = {
            type = "app";
            program = "${pkgs.writeShellScript "open-cv" ''
              exec ${pkgs.xdg-utils}/bin/xdg-open ${self.packages.${pkgs.system}.default}/cv.pdf
            ''}";
          };
          watch = {
            type = "app";
            program = "${pkgs.writeShellScript "watch-cv" ''
              echo cv.tex | ${pkgs.entr}/bin/entr ${tex}/bin/pdflatex cv.tex
            ''}";
          };
        }
      );

      devShells = forAllSystems (
        pkgs: tex: {
          default = pkgs.mkShell {
            packages = [
              tex
              pkgs.entr
            ];
          };
        }
      );
    };
}
