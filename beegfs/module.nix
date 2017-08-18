{ config, lib, pkgs, ...} :

with lib;

let
  cfg = config.services.beegfs;

  configMgmtd = pkgs.writeText "beegfs-mgmgt.conf" ''
    storeMgmtdDirectory = ${cfg.mgmtd.storeDir}
    storeAllowFirstRunInit = false

    ${cfg.mgmtd.extraConfig}
  '';

  configMeta = pkgs.writeText "beegfs-meta.conf" ''
    storeMetaDirectory = ${cfg.meta.storeDir}
    sysMgmtdHost = ${cfg.mgmtHost}
    storeAllowFirstRunInit = false

    ${cfg.mgmtd.extraConfig}
  '';

  configStorage = pkgs.writeText "beegfs-storage.conf" ''
    storeStorageDirectory = ${cfg.storage.storeDir}
    sysMgmtdHost = ${cfg.mgmtHost}
    storeAllowFirstRunInit = false

    ${cfg.storage.extraConfig}
  '';

  configClient = ''
    sysMgmtdHost = ${cfg.mgmtHost}
  '';

in
  {
    ###### interface 

    options = {
      services.beegfs = {

        mgmtHost = mkOption {
          type = types.str;
          default = null;
          example = "master";
          description = ''
            Hostname of mgmt node. This options is needed if storage of meta data
            service is enabled.
          '';  
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
    };

    ###### implementation
    config = 
    mkIf ( cfg.mgmtd.enable || 
           cfg.meta.enable ||
           cfg.storage.enable ) {


      environment.systemPackages = [ pkgs.beegfs ];

      environment.etc."beegfs-client.conf" = {
        enable = true;
        text = configClient;
      };

      systemd.services.beegfsMgmtd = mkIf cfg.mgmtd.enable {
        path = with pkgs; [ beegfs ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "zfs.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.beegfs}/bin/beegfs-mgmtd cfgFile=${configMgmtd} pidFile=/run/beegfs-mgmtd.pid";
          PIDfile = "/run/beegfs-mgmtd.pid"; 
          TimeoutStopSec = "300";
        };
      };

      systemd.services.beegfsMeta = mkIf cfg.meta.enable {
        path = with pkgs; [ beegfs ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "zfs.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.beegfs}/bin/beegfs-meta cfgFile=${configMeta} pidFile=/run/beegfs-mgmtd.pid";
          PIDfile = "/run/beegfs-meta.pid"; 
          TimeoutStopSec = "300";
        };
      };
      
      systemd.services.beegfsStorage = mkIf cfg.storage.enable {
        path = with pkgs; [ beegfs ];
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "zfs.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.beegfs}/bin/beegfs-storage cfgFile=${configStorage} pidFile=/run/beegfs-mgmtd.pid";
          PIDfile = "/run/beegfs-storage.pid"; 
          TimeoutStopSec = "300";
        };
      };
    };
  }

