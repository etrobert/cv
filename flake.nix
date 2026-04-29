{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, self }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-basic geometry hyperref enumitem titlesec parskip ec cm-super;
          };
          cv = pkgs.stdenvNoCC.mkDerivation {
            name = "cv";
            src = ./.;
            buildInputs = [ tex ];
            buildPhase = "pdflatex cv.tex";
            installPhase = "install -Dm644 cv.pdf $out/cv.pdf";
          };
        in
        { default = cv; });

      apps = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          default = {
            type = "app";
            program = "${pkgs.writeShellScript "open-cv" ''
              exec ${pkgs.xdg-utils}/bin/xdg-open ${self.packages.${system}.default}/cv.pdf
            ''}";
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          tex = pkgs.texlive.combine {
            inherit (pkgs.texlive) scheme-basic geometry hyperref enumitem titlesec parskip ec cm-super;
          };
        in
        {
          default = pkgs.mkShell {
            packages = [ tex ];
          };
        });
    };
}
