
Used together with crontab and rsnapshot.

```
$ bash compressDir.sh --help
log system : system

compressDir vers. 0.3.0, using libfunc vers. 0.1.0
Small backup program that creates tar.gz archives files (one par day) from a list of
target directories. For each target, keeps 5 archives, oldest ones are removed.

Usage : compressDir [options]

  Help:
    -h, --help               Display help and exit.
    -v, --verbose            Add some status and info messages.

  Create backup files:
    -p, --pretend            Show what would be run.
    -r, --realrun            Here we go ! rm -rf * :)

 --pretend is the default behavior when no options are supplied.
 --realrun and --pretend are opposed. They can not be used simultaneously.
 --realrun is required to really create the archives.

compressDir.sh : main[237] : exiting with status : 0
```

## Archives root directory

```
$ pwd
/home/user
$ ls -l archives/{DoT_*,dev*,pass*}
-rw-r----- 1 user user    20807  3 Jun  10:30 archives/DoT_gnupg-2017-06-03.tar.gz
-rw-r----- 1 user user    20807  4 Jun  10:30 archives/DoT_gnupg-2017-06-04.tar.gz
-rw-r----- 1 user user    20811  5 Jun  10:30 archives/DoT_gnupg-2017-06-05.tar.gz
-rw-r----- 1 user user    20811  6 Jun  10:30 archives/DoT_gnupg-2017-06-06.tar.gz
-rw-r----- 1 user user    20811  7 Jun  10:30 archives/DoT_gnupg-2017-06-07.tar.gz
-rw-r----- 1 user user    36667  3 Jun  10:30 archives/DoT_ssh-2017-06-03.tar.gz
-rw-r----- 1 user user    36667  4 Jun  10:30 archives/DoT_ssh-2017-06-04.tar.gz
-rw-r----- 1 user user    36687  5 Jun  10:30 archives/DoT_ssh-2017-06-05.tar.gz
-rw-r----- 1 user user    36687  6 Jun  10:30 archives/DoT_ssh-2017-06-06.tar.gz
-rw-r----- 1 user user    36703  7 Jun  10:30 archives/DoT_ssh-2017-06-07.tar.gz
-rw-r----- 1 user user 11455696  3 Jun  10:30 archives/dev-2017-06-03.tar.gz
-rw-r----- 1 user user 11478478  4 Jun  10:30 archives/dev-2017-06-04.tar.gz
-rw-r----- 1 user user 11510721  5 Jun  10:30 archives/dev-2017-06-05.tar.gz
-rw-r----- 1 user user 11510520  6 Jun  10:30 archives/dev-2017-06-06.tar.gz
-rw-r----- 1 user user 11525811  7 Jun  10:30 archives/dev-2017-06-07.tar.gz
-rw-r----- 1 user user     5390  3 Jun  10:30 archives/pass-2017-06-03.tar.gz
-rw-r----- 1 user user     5390  4 Jun  10:30 archives/pass-2017-06-04.tar.gz
-rw-r----- 1 user user     5401  5 Jun  10:30 archives/pass-2017-06-05.tar.gz
-rw-r----- 1 user user     5401  6 Jun  10:30 archives/pass-2017-06-06.tar.gz
-rw-r----- 1 user user     5401  7 Jun  10:30 archives/pass-2017-06-07.tar.gz
```

## Output examples

```
$ bash compressDir.sh --realrun
log system : system
compressDir, vers. 0.3.0
parsing configuration file : /home/user/.config/compressDir/targets.list
# = comment   . = skip   W = warning   T = valid target
##############.TTTT. done ! :)
4 valid targets
[ INFO ] created dev-2017-06-07.tar.gz :-)
        [ removed ] dev-2017-06-02.tar.gz
[ INFO ] created pass-2017-06-07.tar.gz :-)
        [ removed ] pass-2017-06-02.tar.gz
[ INFO ] created DoT_ssh-2017-06-07.tar.gz :-)
        [ removed ] DoT_ssh-2017-06-02.tar.gz
[ INFO ] created DoT_gnupg-2017-06-07.tar.gz :-)
        [ removed ] DoT_gnupg-2017-06-02.tar.gz
```

```
$ bash compressDir.sh --realrun --verbose
log system : system
compressDir, vers. 0.3.0
parsing configuration file : /home/user/.config/compressDir/targets.list
# = comment   . = skip   W = warning   T = valid target
##############.TTTT. done ! :)
4 valid targets
entering main loop ...
[ INFO ] created dev-2017-06-07.tar.gz :-)
        remove oldest archives loop
                base name : dev-*.tar.gz
                6 files in directory /home/user/archives
                keeping 5 files
                        [ keeped ] dev-2017-06-07.tar.gz
                        [ keeped ] dev-2017-06-06.tar.gz
                        [ keeped ] dev-2017-06-05.tar.gz
                        [ keeped ] dev-2017-06-04.tar.gz
                        [ keeped ] dev-2017-06-03.tar.gz
                        [ removed ] dev-2017-06-02.tar.gz
[ INFO ] created pass-2017-06-07.tar.gz :-)
        remove oldest archives loop
                base name : pass-*.tar.gz
                6 files in directory /home/user/archives
                keeping 5 files
                        [ keeped ] pass-2017-06-07.tar.gz
                        [ keeped ] pass-2017-06-06.tar.gz
                        [ keeped ] pass-2017-06-05.tar.gz
                        [ keeped ] pass-2017-06-04.tar.gz
                        [ keeped ] pass-2017-06-03.tar.gz
                        [ removed ] pass-2017-06-02.tar.gz
[ INFO ] created DoT_ssh-2017-06-07.tar.gz :-)
        remove oldest archives loop
                base name : DoT_ssh-*.tar.gz
                6 files in directory /home/user/archives
                keeping 5 files
                        [ keeped ] DoT_ssh-2017-06-07.tar.gz
                        [ keeped ] DoT_ssh-2017-06-06.tar.gz
                        [ keeped ] DoT_ssh-2017-06-05.tar.gz
                        [ keeped ] DoT_ssh-2017-06-04.tar.gz
                        [ keeped ] DoT_ssh-2017-06-03.tar.gz
                        [ removed ] DoT_ssh-2017-06-02.tar.gz
[ INFO ] created DoT_gnupg-2017-06-07.tar.gz :-)
        remove oldest archives loop
                base name : DoT_gnupg-*.tar.gz
                6 files in directory /home/user/archives
                keeping 5 files
                        [ keeped ] DoT_gnupg-2017-06-07.tar.gz
                        [ keeped ] DoT_gnupg-2017-06-06.tar.gz
                        [ keeped ] DoT_gnupg-2017-06-05.tar.gz
                        [ keeped ] DoT_gnupg-2017-06-04.tar.gz
                        [ keeped ] DoT_gnupg-2017-06-03.tar.gz
                        [ removed ] DoT_gnupg-2017-06-02.tar.gz
compressDir exiting ... :)
```

