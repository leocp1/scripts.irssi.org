let
  pkgs = import <nixpkgs> {};

  inherit (pkgs) lib fetchurl buildPerlPackage;

  inherit (pkgs.perlPackages) PPI PerlTidy PerlCritic;

  TreeXPathEngine = buildPerlPackage rec {
    pname = "Tree-XPathEngine";
    version = "0.05";
    src = fetchurl {
      url =
        "https://cpan.metacpan.org/authors/id/M/MI/MIROD/Tree-XPathEngine-0.05.tar.gz";
      sha256 = "1vbbw8wxm79r3xbra8narw1dqvm34510q67wbmg2zmj6zd1k06r9";
    };
    meta = {
      description = "A re-usable XPath engine";
    };
  };

  PPIxXPath = buildPerlPackage rec {
    pname = "PPIx-XPath";
    version = "2.02";
    src = fetchurl {
      url =
        "https://cpan.metacpan.org/authors/id/D/DA/DAKKAR/PPIx-XPath-2.02.tar.gz";
      sha256 = "1lmx7sw7k0x9pf7s2c1bln3n96spqlc8lxclz1q968cfs8n5yn8s";
    };
    doCheck = false;
    propagatedBuildInputs = [
      PPI
      TreeXPathEngine
    ];
    meta = {
      description = "An XPath implementation for the PDOM";
    };
  };

  pp = with pkgs.perlPackages; [
    PerlPrereqScanner
    YAMLTiny
  ] ++ [
    TreeXPathEngine
    PPIxXPath
  ];

  ourperl = pkgs.perl.withPackages (ps: pp);

  # Temporary until https://github.com/NixOS/nixpkgs/pull/72831 merged
  makeFullPerlPath = let
    inherit (pkgs.perlPackages) makePerlPath requiredPerlModules;
  in
    deps: makePerlPath (requiredPerlModules deps);

  ourirssi = pkgs.irssi.overrideAttrs (
    oldAttrs: {
      buildInputs = oldAttrs.buildInputs ++ [ pkgs.makeWrapper ourperl ];
      postFixup = ''
        wrapProgram "$out/bin/irssi" --prefix PERL5LIB : \
          "${makeFullPerlPath pp}"
      '';
    }
  );

in

pkgs.mkShell {
  buildInputs =
    with pkgs; [
      zsh
      ourirssi
      ourperl
      PerlTidy
      PerlCritic
    ];
  shellHook = ''
    export PERL5LIB="${ourirssi}/lib/perl5''${PERL5LIB:+:$PERL5LIB}"
  '';
}
