{
  network.description = "JIRA";

  jira =
    { config, pkgs, ... }:
    { 
      nixpkgs.config = {
        allowUnfree = true;
      };

      services.jira = {
        enable = true;
        proxy = {
          enable = true;
          name = "jira.robinsuter.ch";
          scheme = "https";
        };
      };
      services.postgresql = {
        enable = true;
      };

      services.nginx = {
        enable = true;
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts."jira.robinsuter.ch" = {
          enableACME = true;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:8091";
            extraConfig = ''
              proxy_connect_timeout 300;
              proxy_send_timeout 300;
              proxy_read_timeout 300;
              send_timeout 300;
              client_max_body_size 30M;
              '';
            };
        };
      };

      networking.firewall.allowedTCPPorts = [ 443 80 ];

      # backup

      services.postgresqlBackup = {
        enable = true;
        databases = [ "jiradb" ];
        location = "/var/backup/jira/jiradb";
        period = "15 02 * * *";
      };

      systemd.timers.jira-backup = {
        description = "Backup JIRA Database and data";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar="*-*-* 02:00:00";
        };
      };

      systemd.services.jira-backup = {
        description = "Backup JIRA Database and data";
        after = [ "aws-access-id-key.service" "aws-secret-key.service" ];
        wants = [ "aws-access-id-key.service" "aws-secret-key.service" ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -exo

          SERVICE=atlassian-jira.service
          DATE=$(date +"%Y_%m_%d-%H-%M-%S")
          TMP_DEST="/tmp/backups/$DATE"
          DESTINATION=/var/backup/jira
          DESTFILENAME="jira-backup-$DATE.tar"
          DESTFILE="$DESTINATION/$DESTFILENAME"

          # get aws keys
          export AWS_ACCESS_KEY_ID=$(cat /run/keys/aws-access-id)
          export AWS_SECRET_ACCESS_KEY=$(cat /run/keys/aws-secret)

          PGBACKUP=/var/backup/jira/jiradb/jiradb.gz

          JIRADATA=/var/lib/jira/data

          S3BUCKET=ba-jira-backup

          mkdir -p $DESTINATION
          mkdir -p $TMP_DEST

          echo "Stopping service $SERVICE"
          systemctl stop $SERVICE

          # backup data
          ${pkgs.rsync}/bin/rsync -av $JIRADATA $TMP_DEST

          # include postgres backup
          if [ -f $PGBACKUP ]; then
            cp $PGBACKUP $TMP_DEST
          fi

          # tar and move to backups
          ${pkgs.gnutar}/bin/tar cvf $DESTFILE -C $TMP_DEST .
          ${pkgs.gzip}/bin/gzip $DESTFILE
          DESTFILE="$DESTFILE.gz"

          # upload to S3
          ${pkgs.awscli}/bin/aws s3api put-object --bucket $S3BUCKET --key $DESTFILENAME --body $DESTFILE

          # clean up
          rm -rf $TMP_DEST

          echo "Starting service $SERVICE"
          systemctl start $SERVICE
          '';
      };
    };
}