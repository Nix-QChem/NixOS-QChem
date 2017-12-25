{ config, lib, pkgs, ...} :

with lib;

let
  cfg = config.services.beegfs;

  # function for the generations of config files
  
  configMgmtd = name: cfg: pkgs.writeText "beegfs-mgmt-${name}.conf" ''
    storeMgmtdDirectory = ${cfg.mgmtd.storeDir}
    storeAllowFirstRunInit = false
    connPortShift = ${toString cfg.connPortShift}
    
    ${cfg.mgmtd.extraConfig}
  '';

  configAdmon = name: cfg: pkgs.writeText "beegfs-admon-${name}.conf" ''
    sysMgmtdHost = ${cfg.mgmtHost}
    connPortShift = ${toString cfg.connPortShift}
    
    ${cfg.admon.extraConfig}
  '';

  configMeta = name: cfg: pkgs.writeText "beegfs-meta-${name}.conf" ''
    storeMetaDirectory = ${cfg.meta.storeDir}
    sysMgmtdHost = ${cfg.mgmtHost}
    connPortShift = ${toString cfg.connPortShift}
    storeAllowFirstRunInit = false

    ${cfg.mgmtd.extraConfig}
  '';

  configStorage = name: cfg: pkgs.writeText "beegfs-storage-${name}.conf" ''
    storeStorageDirectory = ${cfg.storage.storeDir}
    sysMgmtdHost = ${cfg.mgmtHost}
    connPortShift = ${toString cfg.connPortShift}
    storeAllowFirstRunInit = false

    ${cfg.storage.extraConfig}
  '';

  configHelperd = name: cfg: pkgs.writeText "beegfs-helperd-${name}.conf" ''
    ${cfg.helperd.extraConfig}
  '';

  configClient = name: cfg: ''
    sysMgmtdHost = ${cfg.mgmtHost}
    connPortShift = ${toString cfg.connPortShift}
    
    ${cfg.client.extraConfig}
  '';

  # function to generate systemd.service entries
  systemdHelperd =  mapAttrs' 
    ( name: cfg:  (nameValuePair "beegfsHelperd-${name}" (mkIf cfg.client.enable {
        path = with pkgs; [ beegfs ];
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = ''
            ${pkgs.beegfs}/bin/beegfs-helperd \
              cfgFile=${configHelperd name cfg} \
              pidFile=/run/beegfs-helperd-${name}.pid
          '';
          PIDfile = "/run/beegfs-helperd-${name}.pid"; 
          TimeoutStopSec = "300";
        };
      }))) cfg;

  systemdAdmon =  mapAttrs'
   (name : cfg: (nameValuePair "beegfsAdmon-${name}" (mkIf cfg.admon.enable {
     path = with pkgs; [ beegfs ];
     wantedBy = [ "multi-user.target" ];
     after = [ "network-online.target" "zfs.target" ];
     serviceConfig = {
       Type = "simple";
       ExecStart = ''
         ${pkgs.beegfs}/bin/beegfs-admon  \
           cfgFile=${configAdmon name cfg} \
           pidFile=/run/beegfs-admon-${name}.pid
       '';
       PIDfile = "/run/beegfs-admon-${name}.pid"; 
       TimeoutStopSec = "300";
     };
   }))) cfg;
       
  systemdMgmtd =  mapAttrs'
   (name : cfg: (nameValuePair "beegfsMgmtd-${name}" (mkIf cfg.mgmtd.enable {
     path = with pkgs; [ beegfs ];
     wantedBy = [ "multi-user.target" ];
     after = [ "network-online.target" "zfs.target" ];
     serviceConfig = {
       Type = "simple";
       ExecStart = ''
         ${pkgs.beegfs}/bin/beegfs-mgmtd  \
           cfgFile=${configMgmtd name cfg} \
           pidFile=/run/beegfs-mgmtd-${name}.pid
       '';
       PIDfile = "/run/beegfs-mgmtd-${name}.pid"; 
       TimeoutStopSec = "300";
     };
   }))) cfg;
       
  systemdMeta =  mapAttrs'
   (name : cfg: (nameValuePair "beegfsMeta-${name}" (mkIf cfg.meta.enable {
      path = with pkgs; [ beegfs ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "zfs.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.beegfs}/bin/beegfs-meta \
          cfgFile=${configMeta name cfg} \
          pidFile=/run/beegfs-mgmtd-${name}.pid
        ''; 
        PIDfile = "/run/beegfs-meta-${name}.pid";
        TimeoutStopSec = "300";
      };
   }))) cfg;
       
  systemdStorage =  mapAttrs'
   (name : cfg: (nameValuePair "beegfsStorage-${name}" (mkIf cfg.storage.enable {
      path = with pkgs; [ beegfs ];
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "zfs.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = '' ${pkgs.beegfs}/bin/beegfs-storage \
          cfgFile=${configStorage name cfg} \
          pidFile=/run/beegfs-mgmtd-${name}.pid
        '';
        PIDfile = "/run/beegfs-storage-${name}.pid"; 
        TimeoutStopSec = "300";
     };
  }))) cfg;


in
  {
    ###### interface 

    options = {
      services.beegfs = mkOption {
        default = {};
        description = ''
          BeeGFS configurations. Every mount point requires a seperate configuration.
        '';

        type = with types; attrsOf (submodule ({ config, ... } : {

        options = {      
        mgmtHost = mkOption {
          type = types.str;
          default = null;
          example = "master";
          description = ''
            Hostname of mgmt node. This options is needed if storage of meta data
            service is enabled.
          '';  
        };
   
        connPortShift = mkOption {
          type = types.int;
          default = 0;
          example = 5;
          description = ''
            For each additional beegfs configuration shift all service TCP/UDP ports by at least 5. 
          '';
        };

        client = {
          enable = mkEnableOption "BeeGFS client";
          
          mountPoint = mkOption {
            type = types.str;
            default = "/beegfs";
            description = ''
              Mount point under which the beegfs should be mounted.
            '';
          };
          
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Addional lines for beegfs-client.conf. See documentation
              for further details.
            '';
          };
        };

        helperd = {
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Addional lines for beegfs-helperd.conf. See documentation
              for further details.
            '';
          };
        };

        mgmtd = {
          enable = mkEnableOption "BeeGFS mgmtd daemon";

          storeDir = mkOption {
            type = types.str;
            default = null;
            example = "/data/beegfs-mgmtd";
            description = ''
              Data directory for mgmtd.
              Must not be shared with other beegfs daemons.
              This directory must exist and it must be initialized
              with "beegfs-setup-mgmtd -C -S 1 -p <storeDir>"
            '';
          };
          
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Addional lines for beegfs-mgmtd.conf. See documentation
              for further details.
            '';
          };

        };

        admon = {
          enable = mkEnableOption "BeeGFS admon daemon";

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Addional lines for beegfs-admon.conf. See documentation
              for further details.
            '';
          };
        };

        meta = {
          enable = mkEnableOption "BeeGFS meta data daemon";

          storeDir = mkOption {
            type = types.str;
            default = null;
            example = "/data/beegfs-meta";
            description = ''
              Data directory for meta data service.
              Must not be shared with other beegfs daemons.
              The underlying filesystem must be mounted with xattr turned on.
              This directory must exist and it must be initialized
              with "beegfs-setup-meta -C -s <serviceID> -p <storeDir>"
            '';
          };
          
          extraConfig = mkOption {
            type = types.str;
            default = "";
            description = ''
              Addional lines for beegfs-meta.conf. See documentation
              for further details.
            '';
          };

        };

        storage = {
          enable = mkEnableOption "BeeGFS storage daemon";

          storeDir = mkOption {
            type = types.str;
            default = null;
            example = "/data/beegfs-storage";
            description = ''
              Data directory for storage service.
              Must not be shared with other beegfs daemons.
              The underlying filesystem must be mounted with xattr turned on.
              This directory must exist and it must be initialized
              with "beegfs-setup-storate -C -s <serviceID> -i <storageTargetID> -p <storeDir>"
            '';
          };

          extraConfig = mkOption {
            type = types.str;
            default = "";
            description = ''
              Addional lines for beegfs-meta.conf. See documentation
              for further details.
            '';
          };
        };
        };
      }));
    };
    };    

    ###### implementation



    config = 
# TODO: a general beegfs.enable
#     mkIf ( cfg.client.enable ||
#           cfg.mgmtd.enable || 
#           cfg.meta.enable ||
#           cfg.storage.enable ) {
      {

      #environment.systemPackages = with pkgs; [ beegfs ];
      # Put the client.conf in the standard location where the
      # commandline tools expect it 
      environment.etc = mapAttrs' 
        ( name: cfg:  (nameValuePair "beegfs/beegfs-client-${name}.conf" (mkIf (cfg.client.enable)
          {
            enable = true;
            text = configClient name cfg;
          }))) cfg;


      ## Client stuff

      # Kernel modules, we need this only once per host.
      boot = mkIf (
          foldr (a: b: a || b) false (map (x: x.client.enable) (collect (x: x ? client) cfg))
          )
      {
        kernelModules = [ "beegfs" ];
        extraModulePackages = [ pkgs.beegfs-module ];
      };


      fileSystems = mapAttrs'
        (name: cfg: (nameValuePair cfg.client.mountPoint (mkIf cfg.client.enable {
            device = "beegfs_nodev";
            fsType = "beegfs";
            mountPoint = cfg.client.mountPoint;
            options = [ "cfgFile=/etc/beegfs/beegfs-client-${name}.conf" "_netdev" ];
          }))) cfg;

      systemd.services = systemdHelperd // systemdMgmtd // systemdAdmon // systemdMeta // systemdStorage;
    };
  }

