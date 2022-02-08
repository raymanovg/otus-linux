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
6. Следуя методичке занулил суперблоки (пока не знаю что такое суперблок и зачем его занулять). Получил для каждого девайса `Unrecognised md component device`. Не знаю пока, что это зничит. `#TODO` 
```
[vagrant@raid ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```
7. Создал RAID 6 на 5 новых устройствах.
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
8. Проверил появились ли новые блочные устройства

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
9. Проверил что RAID собрался нормально

```
[vagrant@raid ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4]
md0 : active raid6 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]

unused devices: <none>
```

> - размер одного чанка 512 кб
> - количество юнитов (в данном случае дисков) в RAID равна 5

10. Посмотрел более подробную информацию по RAID

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

11. Для того, чтобы быть уверенным, что OS запомнила какой RAID требуется создать и какие компоненты (диски, разделы, lvm) в него входят создадал файл `mdadm.comf`

- Сначала убедился, что информация по RAID верна

```
[vagrant@raid ~]$ sudo mdadm --detail --scan --verbose
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=raid:0 UUID=78762ac5:ebaf239f:c966d517:0c63f3be
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf
```
- А затем создал файл mdadm.conf

```
[vagrant@raid ~]$ sudo  echo "DEVICE partitions" > mdadm.conf
 ```
 ```
 [vagrant@raid ~]$ sudo mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> mdadm.conf
 ```
 ```
 [vagrant@raid ~]$ cat mdadm.conf
DEVICE partitions
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=raid:0 UUID=78762ac5:ebaf239f:c966d517:0c63f3be
```

