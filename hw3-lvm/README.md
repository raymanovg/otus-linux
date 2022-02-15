# ДЗ 3. LVM.

## Настройка LVM

1. Скопировал содержимое Vagrantfile https://gitlab.com/otus_linux/stands-03-lvm/-/blob/master/Vagrantfile
2. Удалил назначени ip адреса т.к виртуалка не поднимается - падает с ошибкой 
```
The IP address configured for the host-only network is not within the
allowed ranges. Please update the address used to be within the allowed
ranges and run the command again.

  Address: 192.168.11.101
  Ranges: 192.168.56.0/21

Valid ranges can be modified in the /etc/vbox/networks.conf file. For
more information including valid format see:

  https://www.virtualbox.org/manual/ch06.html#network_hostonly
```

3. Посмотрел существующие блочные устройства
```
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
|-sda1                    8:1    0    1M  0 part
|-sda2                    8:2    0    1G  0 part /boot
`-sda3                    8:3    0   39G  0 part
  |-VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  `-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```
```
[vagrant@lvm ~]$ sudo lvmdiskscan
  /dev/VolGroup00/LogVol00 [     <37.47 GiB]
  /dev/VolGroup00/LogVol01 [       1.50 GiB]
  /dev/sda2                [       1.00 GiB]
  /dev/sda3                [     <39.00 GiB] LVM physical volume
  /dev/sdb                 [      10.00 GiB]
  /dev/sdc                 [       2.00 GiB]
  /dev/sdd                 [       1.00 GiB]
  /dev/sde                 [       1.00 GiB]
  4 disks
  3 partitions
  0 LVM physical volume whole disks
  1 LVM physical volume
```

4. Создал Phisical volume (далее pv) на диске /dev/sdb

```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
```
5. Проверил создался ли pv

```
[vagrant@lvm ~]$ sudo pvscan
  PV /dev/sda3   VG VolGroup00      lvm2 [<38.97 GiB / 0    free]
  PV /dev/sdb                       lvm2 [10.00 GiB]
  Total: 2 [<48.97 GiB] / in use: 1 [<38.97 GiB] / in no VG: 1 [10.00 GiB]
```
```
[vagrant@lvm ~]$ sudo pvdisplay
  --- Physical volume ---
  PV Name               /dev/sda3
  VG Name               VolGroup00
  PV Size               <39.00 GiB / not usable 30.00 MiB
  Allocatable           yes (but full)
  PE Size               32.00 MiB
  Total PE              1247
  Free PE               0
  Allocated PE          1247
  PV UUID               vrrtbx-g480-HcJI-5wLn-4aOf-Olld-rC03AY

  "/dev/sdb" is a new physical volume of "10.00 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdb
  VG Name
  PV Size               10.00 GiB
  Allocatable           NO
  PE Size               0
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               3kZcgl-mLPB-Ljhl-k8pl-X0w0-gNNQ-Lil109
```

> pv создался, но не принадлежит ни одной Volume Group (далее VG).

6. Создал абстракцию VG otus 

```
[vagrant@lvm ~]$ sudo vgcreate otus /dev/sdb
  Volume group "otus" successfully created
```
7. Посмотрел создалась ли VG 
```
[vagrant@lvm ~]$ sudo vgscan
  Reading volume groups from cache.
  Found volume group "VolGroup00" using metadata type lvm2
  Found volume group "otus" using metadata type lvm2
```
> VG otus создалась

8. Проверил появилась ли VG otus у PV /dev/sdb

```
[vagrant@lvm ~]$ sudo pvscan
  PV /dev/sda3   VG VolGroup00      lvm2 [<38.97 GiB / 0    free]
  PV /dev/sdb    VG otus            lvm2 [<10.00 GiB / <10.00 GiB free]
  Total: 2 [48.96 GiB] / in use: 2 [48.96 GiB] / in no VG: 0 [0   ]
```
> Появилась, равна otus

9. Посмотрел информацию о VG

```
[vagrant@lvm ~]$ sudo vgdisplay otus
  --- Volume group ---
  VG Name               otus
  System ID
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  2
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       2047 / <8.00 GiB
  Free  PE / Size       512 / 2.00 GiB
  VG UUID               z2yZad-irtA-j7jT-ddId-PwAw-DCZh-JwN2us
```

10. Создал Logical Volume (далее LV) test c размером равным 80% от свободного места в VG otus

```
[vagrant@lvm ~]$ sudo lvcreate -l+80%FREE -n test otus
Logical volume "test" created.
```
11. Проверил создалась ли LV

```
[vagrant@lvm ~]$ sudo lvscan
  ACTIVE            '/dev/VolGroup00/LogVol00' [<37.47 GiB] inherit
  ACTIVE            '/dev/VolGroup00/LogVol01' [1.50 GiB] inherit
  ACTIVE            '/dev/otus/test' [<8.00 GiB] inherit
```

12. Посмотрел детальную информацию по `LV` `/dev/otus/test`

```
[vagrant@lvm ~]$ sudo lvdisplay /dev/otus/test
  --- Logical volume ---
  LV Path                /dev/otus/test
  LV Name                test
  VG Name                otus
  LV UUID                kWLv9c-j4wJ-15lj-VCPB-GuRq-dP7J-Qb8GrN
  LV Write Access        read/write
  LV Creation host, time lvm, 2022-02-15 21:33:38 +0000
  LV Status              available
  # open                 0
  LV Size                <8.00 GiB
  Current LE             2047
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:2
```
> - LV содалась правильно 
> - Размер LV соответсвует 80% от свободного места в VG otus

13. Попробывал команды `vgs` и `lvs` для получения сжатой информации о существующих `VG` и `LV`.

```
[vagrant@lvm ~]$ sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g    0
  otus         1   1   0 wz--n- <10.00g 2.00g
```

```
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  test     otus       -wi-a-----  <8.00g
```

> - `vgs` выводит в сжатом виде информацию о существующих в систем `VG`
> - `lvs` выводит в сжатом виде информацию о существующих `LV`

14. Создал еще один LV на 100 мб над VG otus из свободного места. На этот раз в указал размер в абсолютных значениях, а не экстетах.

```
[vagrant@lvm ~]$ sudo lvcreate -L 100M -n small otus
  Logical volume "small" created.
```

15. Проверил, что `LV` создалась

```
[vagrant@lvm ~]$ sudo lvs
  LV       VG         Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  LogVol00 VolGroup00 -wi-ao---- <37.47g
  LogVol01 VolGroup00 -wi-ao----   1.50g
  small    otus       -wi-a----- 100.00m
  test     otus       -wi-a-----  <8.00g
```

16. Создал файловую систему на LV test (/dev/otus/test)

```
[vagrant@lvm ~]$ sudo mkfs.ext4 /dev/otus/test
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
524288 inodes, 2096128 blocks
104806 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2147483648
64 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks:
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
```
17. Создал директорию /data и смонтировал в него LV /dev/otus/test

```
[vagrant@lvm ~]$ sudo mkdir /data
[vagrant@lvm ~]$ sudo mount /dev/otus/test /data
```
18. Проверил правильно ли все смонтировалось

```
[vagrant@lvm ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
|-sda1                    8:1    0    1M  0 part
|-sda2                    8:2    0    1G  0 part /boot
`-sda3                    8:3    0   39G  0 part
  |-VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  `-VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
|-otus-test             253:2    0    8G  0 lvm  /data
`-otus-small            253:3    0  100M  0 lvm
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

```
[vagrant@lvm ~]$ mount | grep /data
/dev/mapper/otus-test on /data type ext4 (rw,relatime,seclabel,data=ordered)
```

## Расширение LVM

1. Создал новую PV на блочном устройстве /dev/sdc

```
[vagrant@lvm ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
```

2. Проверил новый PV

```
[vagrant@lvm ~]$ sudo pvdisplay /dev/sdc
  "/dev/sdc" is a new physical volume of "2.00 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdc
  VG Name
  PV Size               2.00 GiB
  Allocatable           NO
  PE Size               0
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               fdpsXx-Yncc-Fy1p-HcEE-zGpi-Y4yT-giSIuS
```

3. Расширил VG otus добавив PV /dev/sdc

```
[vagrant@lvm ~]$ sudo vgextend otus /dev/sdc
  Volume group "otus" successfully extended
```

4. Проверил, что новый PV добавился в VG otus

```
[vagrant@lvm ~]$ sudo vgdisplay -v otus | grep 'PV Name'
  PV Name               /dev/sdb
  PV Name               /dev/sdc
```

5. Убедился, что размер VG увеличился 

```
[vagrant@lvm ~]$ sudo vgs
  VG         #PV #LV #SN Attr   VSize   VFree
  VolGroup00   1   2   0 wz--n- <38.97g     0
  otus         2   2   0 wz--n-  11.99g <3.90g
```

> Размер стал 11.99 гб, а было 10.00 гб

6. Проверил размер дискового пространства в /data

```
[vagrant@lvm ~]$ sudo df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G   36M  7.3G   1% /data
```

7. Сымитировал занятое место 

```
[vagrant@lvm ~]$ dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress
dd: failed to open '/data/test.log': Permission denied
[vagrant@lvm ~]$ sudo dd if=/dev/zero of=/data/test.log bs=1M count=8000 status=progress
7729053696 bytes (7.7 GB) copied, 9.032805 s, 856 MB/s
dd: error writing '/data/test.log': No space left on device
7880+0 records in
7879+0 records out
8262189056 bytes (8.3 GB) copied, 9.65065 s, 856 MB/s
```

8. Еще раз проверил размер

```
[vagrant@lvm ~]$ sudo df -Th /data/
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data
```

9. Добавил в LV /dev/otus/test еще 80% от свободного места в VG otus.

```
[vagrant@lvm ~]$ sudo lvextend -l+80%FREE /dev/otus/test
  Size of logical volume otus/test changed from <8.00 GiB (2047 extents) to <11.12 GiB (2846 extents).
  Logical volume otus/test successfully resized.
``` 
> Было 8.00 гб, стало 11.12 гб.

10. Проверим информацию по LV /dev/otus/test

```
[vagrant@lvm ~]$ sudo lvs /dev/otus/test
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  test otus -wi-ao---- <11.12g
```

> Размер LV увеличился

11. Посмотрел размер директории /data к которой смонтирован LV /dev/otus/test

```
[vagrant@lvm ~]$ sudo df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4  7.8G  7.8G     0 100% /data
```

> Размер файловой системы не изменился 

12. Сделал resize файловой системы

```
[vagrant@lvm ~]$ sudo resize2fs /dev/otus/test
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/otus/test is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/otus/test is now 2914304 blocks long.
```

13. Еще раз проверил размер директории /data

```
[vagrant@lvm ~]$ sudo df -Th /data
Filesystem            Type  Size  Used Avail Use% Mounted on
/dev/mapper/otus-test ext4   11G  7.8G  2.6G  76% /data
```

> Размер поменялся. Появилось еще 2.5 гб свободного пространства

## Уменьшение LV














