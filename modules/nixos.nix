# NixOS module for PhonerLite: programs.phonerlite.enable = true;
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.phonerlite;
in
{
  options.programs.phonerlite = {
    enable = lib.mkEnableOption "PhonerLite SIP softphone (via Wine)";
    package = lib.mkPackageOption pkgs "phonerlite" { };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
