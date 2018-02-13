{ config, lib, pkgs, ... }:


{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "mptspi" "floppy" "sd_mod" "sr_mod" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/cee813d3-ee83-47e1-977e-d03c43655263";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/caec8a2b-c1d9-4d51-89a0-844caaea55d9"; }
    ];

  nix.maxJobs = lib.mkDefault 2;
}
