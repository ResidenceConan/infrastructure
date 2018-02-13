{
  jira =
    { config, pkgs, ... }:
    { 
      imports = [ ./hsr-host-configuration.nix ];
      deployment.targetHost = "152.96.56.73";
    };
}