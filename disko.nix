{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = [
          {
            name = "ESP";
            start = "1MiB";
            end = "513MiB";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          }
          {
            name = "luks";
            start = "513MiB";
            end = "100%";
            content = {
              type = "luks";
              name = "cryptlvm";
              content = {
                type = "lvm";
                lvs = [
                  {
                    name = "swap";
                    size = "8G";
                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  }
                  {
                    name = "root";
                    size = "100%FREE";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/";
                    };
                  }
                ];
              };
            };
          }
        ];
      };
    };
  };
}
