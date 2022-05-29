{
  description = "A report built with Pandoc, XeLaTex and a custom font";

  inputs = {
      nixpkgs.url = "nixpkgs";
      styles.url = github:citation-style-language/styles;
      styles.flake = false;
  };
  outputs = { self, nixpkgs, styles }: {

    packages.x86_64-linux.pandocWithDiagrams = (
        let
            system = "x86_64-linux";
            pkgs = nixpkgs.legacyPackages.${system};
            fonts = pkgs.makeFontsConf { fontDirectories = [ pkgs.dejavu_fonts ]; };
            dgram = ./dgram.lua;
            execName = "pandocDgram";
            pandocDgram = pkgs.writeShellScriptBin execName ''
              echo "converting"
              export FONTCONFIG_FILE=${fonts}
              pandoc \
                  --lua-filter=${dgram} \
                  --filter pandoc-crossref \
                  -M date="`date "+%B %e, %Y"`" \
                  --csl ${styles}/chicago-fullnote-bibliography.csl \
                  --citeproc \
                  --pdf-engine=xelatex \
                  "$@"
              echo "pandoc done"
              '';
            dgramDependencies = with pkgs; [
                pandoc
                haskellPackages.pandoc-crossref
                texlive.combined.scheme-small
                gnome.librsvg # for conversion from svg to pdf
                graphviz
                plantuml
                nodePackages.vega-cli
                # the following is waiting on https://github.com/NixOS/nixpkgs/pull/162434
                (nodePackages.vega-lite.override {
                    postInstall = ''
                        cd node_modules
                        for dep in ${nodePackages.vega-cli}/lib/node_modules/vega-cli/node_modules/*; do
                          if [[ ! -d ''${dep##*/} ]]; then
                            ln -s "${nodePackages.vega-cli}/lib/node_modules/vega-cli/node_modules/''${dep##*/}"
                          fi
                        done
                      '';})
                nodePackages.mermaid-cli
                svgbob
                ];
        in
          pkgs.symlinkJoin {
              name = execName;
              paths = [ pandocDgram ] ++ dgramDependencies;
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/${execName} --prefix PATH : $out/bin
                for f in $out/lib/node_modules/.bin/*; do
                   path="$(readlink --canonicalize-missing "$f")"
                   ln -s "$path" "$out/bin/$(basename $f)"
                done
              '';
          }
        );

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.pandocWithDiagrams;
  };
}
