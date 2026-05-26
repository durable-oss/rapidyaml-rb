{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [ git libyaml openssl rapidyaml boehmgc ];

  languages.ruby.enable = true;
  languages.cplusplus.enable = true;

  enterShell = ''
  '';
}
