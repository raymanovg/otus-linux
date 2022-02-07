1. Создание раздела: `sudo gdisk /dev/sdb`
2. Создание raid: `sudo mdadm --create --verbose /dev/md/raid1_ex --level=1 --raid-devices=4 /dev/sdc /dev/sdd /dev/sde /dev/sdf`
3. Инфа о raid: `sudo mdadm --detail /dev/md/raid1_ex`
4. Добавление диска в raid: ` sudo mdadm --add /dev/md/raid1_ex /dev/sdb`. /dev/sdb уходит в spare (в ожидание). Если какой-то диск из raid отваливается, то он приходит ему на смену.
5. Имитируем отвалившийся диск: `sudo mdadm /dev/md/raid1_ex --fail /dev/sdf`
6. Также инфу по raid можно глянуть тут: `cat /proc/mdstat`
7. Тестирование диска: `sudo hdparm -Tt --direct /dev/sda`
8. Получение доп информации о диске: `sudo smartctl -a /dev/sda`