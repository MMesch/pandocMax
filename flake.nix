{
  description = "A report built with Pandoc, XeLaTex and a custom font";

  inputs = {
      nixpkgs.url = "nixpkgs";
      styles = {
        url = github:citation-style-language/styles;
        flake = false;
      };
      columns = {
        url = github:dialoa/columns;
        flake = false;
      };
      dgram.url = github:mmesch/dgram;
      flake-compat = {
          url = github:edolstra/flake-compat;
          flake = false;
      };
  };
  outputs = { self, nixpkgs, styles, columns, dgram, flake-compat }: {

    packages.x86_64-linux.pandocMax = (
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
            fonts = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
        in
        (pkgs.writeShellApplication {
          name = "pandocMax";
          runtimeInputs =
              with pkgs; [
                pandoc
                haskellPackages.pandoc-crossref
                texlive.combined.scheme-full
                  ];
          text = ''
            echo "pandocMax"
            pandoc \
                --lua-filter=${dgram.packages.x86_64-linux.pandocScript}/dgram.lua \
                --lua-filter=${columns}/columns.lua \
                --filter pandoc-crossref \
                -M date="$(date "+%B %e, %Y")" \
                --csl ${styles}/chicago-fullnote-bibliography.csl \
                --citeproc \
                --pdf-engine=xelatex \
                "$@"
            echo "pandoc done"
            '';
        }));

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.pandocMax;
  };
}
