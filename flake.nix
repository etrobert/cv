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
                scheme-basic # minimal TeX Live base (plain TeX, latex, etc.)
                geometry # set page margins and paper size
                hyperref # clickable links and PDF metadata
                enumitem # customize list spacing and labels
                titlesec # style section headings
                parskip # paragraph spacing instead of indentation
                latexindent # LaTeX formatter (used by editors)
                xetex # XeTeX engine, required for xelatex
                fontspec # load system OTF/TTF fonts in XeTeX
                raleway # Raleway typeface used in the CV
                graphics # include images (\includegraphics)
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
            buildPhase = "xelatex cv.tex";
            installPhase = "install -Dm644 cv.pdf $out/cv.pdf";
          };
          letter = pkgs.stdenvNoCC.mkDerivation {
            name = "letter";
            src = ./.;
            buildInputs = [ tex ];
            buildPhase = "xelatex letter.tex";
            installPhase = "install -Dm644 letter.pdf $out/letter.pdf";
          };
        }
      );

      apps = forAllSystems (
        pkgs: tex:
        let
          system = pkgs.stdenv.hostPlatform.system;
          open = if pkgs.stdenv.isDarwin then "open" else "${pkgs.xdg-utils}/bin/xdg-open";
        in
        {
          default = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "open-cv" ''
                exec ${open} ${self.packages.${system}.default}/cv.pdf
              ''
            );
          };
          watch = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "watch-cv" ''
                echo cv.tex | ${pkgs.entr}/bin/entr ${tex}/bin/xelatex cv.tex
              ''
            );
          };
          watch-letter = {
            type = "app";
            program = toString (
              pkgs.writeShellScript "watch-letter" ''
                echo letter.tex | ${pkgs.entr}/bin/entr ${tex}/bin/xelatex letter.tex
              ''
            );
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
