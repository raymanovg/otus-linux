1. Создание раздела: `sudo gdisk /dev/sdb`
2. Создание raid: `sudo mdadm --create --verbose /dev/md/raid1_ex --level=1 --raid-devices=4 /dev/sdc /dev/sdd /dev/sde /dev/sdf`
3. Инфа о raid: `sudo mdadm --detail /dev/md/raid1_ex`
4. Добавление диска в raid: ` sudo mdadm --add /dev/md/raid1_ex /dev/sdb`. /dev/sdb уходит в spare (в ожидание). Если какой-то диск из raid отваливается, то он приходит ему на смену.
5. Имитируем отвалившийся диск: `sudo mdadm /dev/md/raid1_ex --fail /dev/sdf`
6. Также инфу по raid можно глянуть тут: `cat /proc/mdstat`
7. Тестирование диска: `sudo hdparm -Tt --direct /dev/sda`
8. Получение доп информации о диске: `sudo smartctl -a /dev/sda`

# ДЗ 2. Сборка RAID.

1. Добавить в Vagrantfile еще дисков.
2. Собрать raid R0/R5/R10 на выбор.
3. Прописать собранный raid в конф, чтобы raid собирался при загрузке.
4. Сломать/починить raid.
5. Создать GPT раздел и 5 партиций смонтировать их на диск.

## Добавление новых дисков в Vagrantfile

1. Скопировал из первого дз `Vagrantfile` и добавил `5` дисков как тут https://github.com/erlong15/otus-linux/blob/master/Vagrantfile
2. Заменил `box.vm.box` на свой `raymanovg/centos-7-5` с обновленным ядром.
3. Запустил виртуалку `vagrant up`.
4. Проверил создались ли дополнительные диски:
```
vagrant@raid ~]$ lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sdf               8:80   0  250M  0 disk
sdd               8:48   0  250M  0 disk
sdb               8:16   0  250M  0 disk
sde               8:64   0  250M  0 disk
sdc               8:32   0  250M  0 disk
sda               8:0    0   10G  0 disk
|-sda2            8:2    0    9G  0 part
| |-centos-swap 253:1    0    1G  0 lvm  [SWAP]
| `-centos-root 253:0    0    8G  0 lvm  / 
`-sda1            8:1    0    1G  0 part /boot
```
## Сборка RAID 6

1. Следуя методичке занулил суперблоки (пока не знаю что такое суперблок и зачем его занулять). Получил для каждого девайса `Unrecognised md component device`. Не знаю пока, что это зничит. `#TODO` 
```
[vagrant@raid ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```
2. Создал RAID 6 на 5 новых устройствах.
```
[vagrant@raid ~]$ mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
mdadm: must be super-user to perform this action
[vagrant@raid ~]$ sudo mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```
3. Проверил появились ли новые блочные устройства

```
[vagrant@raid ~]$ lsblk
NAME            MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sdf               8:80   0  250M  0 disk
`-md0             9:0    0  744M  0 raid6
sdd               8:48   0  250M  0 disk
`-md0             9:0    0  744M  0 raid6
sdb               8:16   0  250M  0 disk
`-md0             9:0    0  744M  0 raid6
sde               8:64   0  250M  0 disk
`-md0             9:0    0  744M  0 raid6
sdc               8:32   0  250M  0 disk
`-md0             9:0    0  744M  0 raid6
sda               8:0    0   10G  0 disk
|-sda2            8:2    0    9G  0 part
| |-centos-swap 253:1    0    1G  0 lvm   [SWAP]
| `-centos-root 253:0    0    8G  0 lvm   /
`-sda1            8:1    0    1G  0 part  /boot
```
4. Проверил что RAID собрался нормально

```
[vagrant@raid ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]

unused devices: <none>
```

> - размер одного чанка 512 кб
> - количество юнитов (в данном случае дисков) в RAID равна 5

5. Посмотрел более подробную информацию по RAID

```
[vagrant@raid ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Tue Feb  8 17:04:18 2022
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Feb  8 17:04:30 2022
             State : clean
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 78762ac5:ebaf239f:c966d517:0c63f3be
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
```

6. Для того, чтобы быть уверенным, что OS запомнила какой RAID требуется создать и какие компоненты (диски, разделы, lvm) в него входят создадал файл `mdadm.comf`

- Сначала убедился, что информация по RAID верна

```
[vagrant@raid ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=raid:0 UUID=78762ac5:ebaf239f:c966d517:0c63f3be
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
```
- А затем создал файл mdadm.conf в /etc/

```
[vagrant@raid ~]$ sudo  echo "DEVICE partitions" > /etc/mdadm.conf
 ```
 ```
[vagrant@raid ~]$ sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
 ```
 ```
[vagrant@raid ~]$ cat /etc/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=raid:0 UUID=78762ac5:ebaf239f:c966d517:0c63f3be
```
## Ломаем и чиним RAID

1. Проверил RAID

```
[root@raid vagrant]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]

unused devices: <none>
```
> - Все диски на месте

2. Зафейлил диск /dev/sde из RAID

```
[root@raid vagrant]# mdadm /dev/md0 --fail /dev/sde
mdadm: set /dev/sde faulty in /dev/md0
```
3. Снова проверил инфу о RAID 

```
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/4] [UUU_U]

unused devices: <none>
```

> Один из дисков зафейлился судя по индикатору `[UUU_U]`

4. Посмотрел подробную инфу 

```
[root@raid vagrant]# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Tue Feb  8 17:04:18 2022
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Feb  8 17:55:18 2022
             State : clean, degraded
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 1
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 78762ac5:ebaf239f:c966d517:0c63f3be
            Events : 19

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync   /dev/sdf

       3       8       64        -      faulty   /dev/sde
```

> Вижу что диск /dev/sde был удален из RAID и находится в состояние faulty. Число активных девайсов 4, работающих 4 и зафейлившихся 1. 

5. Удалил только что сломанный диск из массива

```
[vagrant@raid ~]$ sudo mdadm /dev/md0 --remove /dev/sde
mdadm: hot removed /dev/sde from /dev/md0
```

6. Проверил снова статус RAID

```
vagrant@raid ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Tue Feb  8 17:04:18 2022
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 4
       Persistence : Superblock is persistent

       Update Time : Tue Feb  8 18:04:05 2022
             State : clean, degraded
    Active Devices : 4
   Working Devices : 4
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 78762ac5:ebaf239f:c966d517:0c63f3be
            Events : 20

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed
       4       8       80        4      active sync   /dev/sdf

```

> Диск /dev/sde исчез

5. Добавил диск /dev/sde обратно в RAID

```
[vagrant@raid ~]$ sudo mdadm /dev/md0 --add /dev/sde
mdadm: added /dev/sde
```

6. Посмотрел статус RAID

```
[vagrant@raid ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sde[5] sdf[4] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]

unused devices: <none>
```

> sde добавился в RAID

7. Посмотрел полную информацию о дисках в RAID

```
[vagrant@raid ~]$ mdadm -D /dev/md0
mdadm: must be super-user to perform this action
[vagrant@raid ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Tue Feb  8 17:04:18 2022
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Tue Feb  8 18:06:43 2022
             State : clean
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : raid:0  (local to host raid)
              UUID : 78762ac5:ebaf239f:c966d517:0c63f3be
            Events : 39

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       5       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
```

> Процесс rebuild-а завершился и диск /dev/sde успешно добавлен в RAID

## Работа с GPT разделами

1. Создал раздел GPT на RAID

```
[vagrant@raid ~]$ sudo parted -s /dev/md0 mklabel gpt
```

2. Создал 5 партиций

```
[vagrant@raid ~]$ sudo parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

[vagrant@raid ~]$ sudo parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

[vagrant@raid ~]$ sudo parted /dev/md0 mkpart primary ext4 40% 60%
Information: You may need to update /etc/fstab.

[vagrant@raid ~]$ sudo parted /dev/md0 mkpart primary ext4 60% 80%
Information: You may need to update /etc/fstab.

[vagrant@raid ~]$ sudo parted /dev/md0 mkpart primary ext4 80% 100%
Information: You may need to update /etc/fstab.
```

3. Проверил создались ли партиции 

```
[vagrant@raid ~]$ lsblk
NAME            MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sdf               8:80   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md
  |-md0p2       259:6    0 148.5M  0 md
  |-md0p5       259:9    0   147M  0 md
  |-md0p3       259:7    0   150M  0 md
  `-md0p1       259:5    0   147M  0 md
sdd               8:48   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md
  |-md0p2       259:6    0 148.5M  0 md
  |-md0p5       259:9    0   147M  0 md
  |-md0p3       259:7    0   150M  0 md
  `-md0p1       259:5    0   147M  0 md
sdb               8:16   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md
  |-md0p2       259:6    0 148.5M  0 md
  |-md0p5       259:9    0   147M  0 md
  |-md0p3       259:7    0   150M  0 md
  `-md0p1       259:5    0   147M  0 md
sde               8:64   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md
  |-md0p2       259:6    0 148.5M  0 md
  |-md0p5       259:9    0   147M  0 md
  |-md0p3       259:7    0   150M  0 md
  `-md0p1       259:5    0   147M  0 md
sdc               8:32   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md
  |-md0p2       259:6    0 148.5M  0 md
  |-md0p5       259:9    0   147M  0 md
  |-md0p3       259:7    0   150M  0 md
  `-md0p1       259:5    0   147M  0 md
sda               8:0    0    10G  0 disk
|-sda2            8:2    0     9G  0 part
| |-centos-swap 253:1    0     1G  0 lvm   [SWAP]
| `-centos-root 253:0    0     8G  0 lvm   /
`-sda1            8:1    0     1G  0 part  /boot
```

> Партиции созданы и на выводе они обазначены как `md0p[1-4]`

4. Созал на этих партициях файловую систему 

```
[vagrant@raid ~]$ for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
37696 inodes, 150528 blocks
7526 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
1984 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38152 inodes, 152064 blocks
7603 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38456 inodes, 153600 blocks
7680 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2024 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
38152 inodes, 152064 blocks
7603 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
2008 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=1024 (log=0)
Fragment size=1024 (log=0)
Stride=512 blocks, Stripe width=1536 blocks
37696 inodes, 150528 blocks
7526 blocks (5.00%) reserved for the super user
First data block=1
Maximum filesystem blocks=33816576
19 block groups
8192 blocks per group, 8192 fragments per group
1984 inodes per group
Superblock backups stored on blocks:
	8193, 24577, 40961, 57345, 73729

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

```

5. Создал каталоги `/raid/part[1-5]`

```
vagrant@raid ~]$ sudo mkdir -p /raid/part{1,2,3,4,5}
[vagrant@raid ~]$ ls -la /raid/
total 0
drwxr-xr-x   7 root root  71 Feb  8 18:24 .
dr-xr-xr-x. 18 root root 256 Feb  8 18:24 ..
drwxr-xr-x   2 root root   6 Feb  8 18:24 part1
drwxr-xr-x   2 root root   6 Feb  8 18:24 part2
drwxr-xr-x   2 root root   6 Feb  8 18:24 part3
drwxr-xr-x   2 root root   6 Feb  8 18:24 part4
drwxr-xr-x   2 root root   6 Feb  8 18:24 part5
```

6. Смонтировал каталоги к вышесозданным партициям

```
[vagrant@raid ~]$ for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done
```

7. Посмотрел информацию по блочным устройствам

```
[vagrant@raid ~]$ lsblk
NAME            MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sdf               8:80   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md    /raid/part4
  |-md0p2       259:6    0 148.5M  0 md    /raid/part2
  |-md0p5       259:9    0   147M  0 md    /raid/part5
  |-md0p3       259:7    0   150M  0 md    /raid/part3
  `-md0p1       259:5    0   147M  0 md    /raid/part1
sdd               8:48   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md    /raid/part4
  |-md0p2       259:6    0 148.5M  0 md    /raid/part2
  |-md0p5       259:9    0   147M  0 md    /raid/part5
  |-md0p3       259:7    0   150M  0 md    /raid/part3
  `-md0p1       259:5    0   147M  0 md    /raid/part1
sdb               8:16   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md    /raid/part4
  |-md0p2       259:6    0 148.5M  0 md    /raid/part2
  |-md0p5       259:9    0   147M  0 md    /raid/part5
  |-md0p3       259:7    0   150M  0 md    /raid/part3
  `-md0p1       259:5    0   147M  0 md    /raid/part1
sde               8:64   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md    /raid/part4
  |-md0p2       259:6    0 148.5M  0 md    /raid/part2
  |-md0p5       259:9    0   147M  0 md    /raid/part5
  |-md0p3       259:7    0   150M  0 md    /raid/part3
  `-md0p1       259:5    0   147M  0 md    /raid/part1
sdc               8:32   0   250M  0 disk
`-md0             9:0    0   744M  0 raid6
  |-md0p4       259:8    0 148.5M  0 md    /raid/part4
  |-md0p2       259:6    0 148.5M  0 md    /raid/part2
  |-md0p5       259:9    0   147M  0 md    /raid/part5
  |-md0p3       259:7    0   150M  0 md    /raid/part3
  `-md0p1       259:5    0   147M  0 md    /raid/part1
sda               8:0    0    10G  0 disk
|-sda2            8:2    0     9G  0 part
| |-centos-swap 253:1    0     1G  0 lvm   [SWAP]
| `-centos-root 253:0    0     8G  0 lvm   /
`-sda1            8:1    0     1G  0 part  /boot
```

> Монитроване прошло успешно


