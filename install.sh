#! /bin/bash
# Copyright (C) Juewuy

[ -z "$url" ] && url="https://fastly.jsdelivr.net/gh/rexname/ShellCrash@master"
type bash &>/dev/null && shtype=bash || shtype=sh
echo='echo -e'
[ -n "$(echo -e | grep e)" ] && {
    echo "\033[31mDash environment is not supported for installation! Please run the installation command after entering the bash command!\033[0m"
    exit
}

echo "***********************************************"
echo "**                 Welcome to                 **"
echo "**                ShellCrash                 **"
echo "**                             by  Juewuy    **"
echo "***********************************************"
# Built-in tools
dir_avail() {
    df $2 $1 | awk '{ for(i=1;i<=NF;i++){ if(NR==1){ arr[i]=$i; }else{ arr[i]=arr[i]" "$i; } } } END{ for(i=1;i<=NF;i++){ print arr[i]; } }' | grep -E 'Ava|Available' | awk '{print $2}'
}
setconfig() {
    configpath=$CRASHDIR/configs/ShellCrash.cfg
    [ -n "$(grep ${1} $configpath)" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >>$configpath
}
webget() {
    # Parameters【$1】represent the download directory, 【$2】represent the online address
    # Parameters【$3】represent output display, 【$4】do not enable redirection
    if curl --version >/dev/null 2>&1; then
        [ "$3" = "echooff" ] && progress='-s' || progress='-#'
        [ -z "$4" ] && redirect='-L' || redirect=''
        result=$(curl -w %{http_code} --connect-timeout 5 $progress $redirect -ko $1 $2)
        [ -n "$(echo $result | grep -e ^2)" ] && result="200"
    else
        if wget --version >/dev/null 2>&1; then
            [ "$3" = "echooff" ] && progress='-q' || progress='-q --show-progress'
            [ "$4" = "rediroff" ] && redirect='--max-redirect=0' || redirect=''
            certificate='--no-check-certificate'
            timeout='--timeout=3'
        fi
        [ "$3" = "echoon" ] && progress=''
        [ "$3" = "echooff" ] && progress='-q'
        wget $progress $redirect $certificate $timeout -O $1 $2
        [ $? -eq 0 ] && result="200"
    fi
}
error_down() {
    $echo "Please refer to \033[32mhttps://github.com/rexname/ShellCrash/blob/master/README_CN.md"
    $echo "\033[33mUse other installation sources to reinstall!\033[0m"
}
# Installation and initialization
gettar() {
    webget /tmp/ShellCrash.tar.gz "$url/bin/ShellCrash.tar.gz"
    if [ "$result" != "200" ]; then
        $echo "\033[33mFile download failed!\033[0m"
        error_down
        exit 1
    else
        $CRASHDIR/start.sh stop 2>/dev/null
        # Decompress
        echo -----------------------------------------------
        echo Starting to decompress files!
        mkdir -p $CRASHDIR >/dev/null
        tar -zxf '/tmp/ShellCrash.tar.gz' -C $CRASHDIR/ || tar -zxf '/tmp/ShellCrash.tar.gz' --no-same-owner -C $CRASHDIR/
        if [ -s $CRASHDIR/init.sh ]; then
            . $CRASHDIR/init.sh >/dev/null || $echo "\033[33mInitialization failed, please try local installation!\033[0m"
        else
            rm -rf /tmp/ShellCrash.tar.gz
            $echo "\033[33mFile decompression failed!\033[0m"
            error_down
            exit 1
        fi
    fi
}
setdir() {
    set_usb_dir() {
        $echo "Please select the installation directory"
        du -hL /mnt | awk '{print " "NR" "$2"  "$1}'
        read -p "Please enter the corresponding number > " num
        dir=$(du -hL /mnt | awk '{print $2}' | sed -n "$num"p)
        if [ -z "$dir" ]; then
            $echo "\033[31mInput error! Please reset!\033[0m"
            set_usb_dir
        fi
    }
    set_asus_dir() {
        echo -e "Please select the USB directory"
        du -hL /tmp/mnt | awk '{print " "NR" "$2"  "$1}'
        read -p "Please enter the corresponding number > " num
        dir=$(du -hL /tmp/mnt | awk '{print $2}' | sed -n "$num"p)
        if [ ! -f "$dir/asusware.arm/etc/init.d/S50downloadmaster" ]; then
            echo -e "\033[31mDownload master auto-start file not found: $dir/asusware.arm/etc/init.d/S50downloadmaster, please check the settings!\033[0m"
            set_asus_dir
        fi
    }
    set_cust_dir() {
        echo -----------------------------------------------
        echo 'Available paths Remaining space:'
        df -h | awk '{print $6,$4}' | sed 1d
        echo 'The path must be in the format with /, note that files written to virtual memory (/tmp,/opt,/sys...) will disappear after a reboot!!!'
        read -p "Please enter a custom path > " dir
        if [ "$(dir_avail $dir)" = 0 ]; then
            $echo "\033[31mPath error! Please reset!\033[0m"
            set_cust_dir
        fi
    }
    echo -----------------------------------------------
    $echo "\033[33mNote: At least about 1MB of disk space is required to install ShellCrash\033[0m"
    if [ -n "$systype" ]; then
        [ "$systype" = "Padavan" ] && dir=/etc/storage
        [ "$systype" = "mi_snapshot" ] && {
            $echo "\033[33mDetected that the current device is a Xiaomi official system, please select the installation location\033[0m"
            [ "$(dir_avail /data)" -gt 256 ] && $echo " 1 Install to the /data directory (recommended, supports soft solidification function)"
            [ "$(dir_avail /userdisk)" -gt 256 ] && $echo " 2 Install to the /userdisk directory (recommended, supports soft solidification function)"
            $echo " 3 Install to a custom directory (not recommended, do not use if you don't understand!)"
            $echo " 0 Exit installation"
            echo -----------------------------------------------
            read -p "Please enter the corresponding number > " num
            case "$num" in
            1)
                dir=/data
                ;;
            2)
                dir=/userdisk
                ;;
            3)
                set_cust_dir
                ;;
            *)
                exit 1
                ;;
            esac
        }
        [ "$systype" = "asusrouter" ] && {
            $echo "\033[33mDetected that the current device is ASUS firmware, please select the installation method\033[0m"
            $echo " 1 Install based on USB device (limited to firmware before September 2023, any USB device needs to be inserted)"
            $echo " 2 Install based on autostart script (only supports Merlin and some non-koolshare official modified firmware)"
            $echo " 3 Install based on USB drive + download master (supports all firmware, limited to ARM devices, USB drive or external hard drive needs to be inserted)"
            $echo " 0 Exit installation"
            echo -----------------------------------------------
            read -p "Please enter the corresponding number > " num
            case "$num" in
            1)
                read -p "Install the script to USB storage/system flash? (1/0) > " res
                [ "$res" = "1" ] && set_usb_dir || dir=/jffs
                usb_status=1
                ;;
            2)
                $echo "If it cannot start normally, please reinstall using the USB method!"
                sleep 2
                dir=/jffs
                ;;
            3)
                echo -e "Please first install and enable the download master on the router web backend, then select the directory where the external storage is located!"
                sleep 2
                set_asus_dir
                ;;
            *)
                exit 1
                ;;
            esac
        }
        [ "$systype" = "ng_snapshot" ] && dir=/tmp/mnt
    else
        $echo " 1 Install in the \033[32m/etc directory\033[0m (suitable for root users)"
        $echo " 2 Install in the \033[32m/usr/share directory\033[0m (suitable for Linux systems)"
        $echo " 3 Install in the \033[32mcurrent user directory\033[0m (suitable for non-root users)"
        $echo " 4 Install in \033[32mexternal storage\033[0m"
        $echo " 5 Manually set the installation directory"
        $echo " 0 Exit installation"
        echo -----------------------------------------------
        read -p "Please enter the corresponding number > " num
        # Set directory
        if [ -z $num ]; then
            echo Installation has been cancelled
            exit 1
        elif [ "$num" = "1" ]; then
            dir=/etc
        elif [ "$num" = "2" ]; then
            dir=/usr/share
        elif [ "$num" = "3" ]; then
            dir=~/.local/share
            mkdir -p ~/.config/systemd/user
        elif [ "$num" = "4" ]; then
            set_usb_dir
        elif [ "$num" = "5" ]; then
            set_cust_dir
        else
            echo Installation has been cancelled!!!
            exit 1
        fi
    fi

    if [ ! -w $dir ]; then
        $echo "\033[31mNo write permission for the $dir directory! Please reset!\033[0m" && sleep 1 && setdir
    else
        $echo "Remaining space in target directory \033[32m$dir\033[0m: $(dir_avail $dir -h)"
        read -p "Confirm installation? (1/0) > " res
        [ "$res" = "1" ] && CRASHDIR=$dir/ShellCrash || setdir
    fi
}
install() {
    echo -----------------------------------------------
    echo Starting to get installation files from the server!
    echo -----------------------------------------------
    gettar
    echo -----------------------------------------------
    echo ShellCrash has been installed successfully!
    [ "$profile" = "~/.bashrc" ] && echo "Please execute the command 【. ~/.bashrc &> /dev/null】 to load environment variables!"
    [ -n "$(ls -l /bin/sh | grep -oE 'zsh')" ] && echo "Please execute the command 【. ~/.zshrc &> /dev/null】 to load environment variables!"
    echo -----------------------------------------------
    $echo "\033[33mEnter the command \033[30;47m crash \033[0;33m to manage!!!\033[0m"
    echo -----------------------------------------------
}
setversion() {
    echo -----------------------------------------------
    $echo "\033[33mPlease select the version you want to install:\033[0m"
    $echo " 1 \033[32mPublic beta (recommended)\033[0m"
    $echo " 2 \033[36mStable version\033[0m"
    $echo " 3 \033[31mDevelopment version\033[0m"
    echo -----------------------------------------------
    read -p "Please enter the corresponding number > " num
    case "$num" in
    2)
        url=$(echo $url | sed 's/master/stable/')
        ;;
    3)
        url=$(echo $url | sed 's/master/dev/')
        ;;
    *) ;;
    esac
}
# Special firmware recognition and marking
[ -f "/etc/storage/started_script.sh" ] && {
    systype=Padavan # Padavan firmware
    initdir='/etc/storage/started_script.sh'
}
[ -d "/jffs" ] && {
    systype=asusrouter # ASUS firmware
    [ -f "/jffs/.asusrouter" ] && initdir='/jffs/.asusrouter'
    [ -d "/jffs/scripts" ] && initdir='/jffs/scripts/nat-start'
}
[ -f "/data/etc/crontabs/root" ] && systype=mi_snapshot # Xiaomi devices
[ -w "/var/mnt/cfg/firewall" ] && systype=ng_snapshot   # NETGEAR devices

# Check root permissions
if [ "$USER" != "root" -a -z "$systype" ]; then
    echo Current user: $USER
    $echo "\033[31mPlease try to use the root user (do not use the sudo command directly!) to execute the installation!\033[0m"
    echo -----------------------------------------------
    read -p "Still want to install? It may cause unknown errors! (1/0) > " res
    [ "$res" != "1" ] && exit 1
fi

if [ -n "$(echo $url | grep master)" ]; then
    setversion
fi
# Get version information
webget /tmp/version "$url/bin/version" echooff
[ "$result" = "200" ] && versionsh=$(cat /tmp/version | grep "versionsh" | awk -F "=" '{print $2}')
rm -rf /tmp/version

# Output
$echo "Latest version: \033[32m$versionsh\033[0m"
echo -----------------------------------------------
$echo "\033[44mIf you encounter problems, please join the TG group to give feedback: \033[42;30m t.me/ShellClash \033[0m"
$echo "\033[37mSupports various OpenWrt-based router devices"
$echo "\033[33mSupports Debian, Centos and other standard Linux systems\033[0m"

if [ -n "$CRASHDIR" ]; then
    echo -----------------------------------------------
    $echo "Detected the old installation directory \033[36m$CRASHDIR\033[0m, do you want to overwrite the installation?"
    $echo "\033[32mConfiguration files will not be removed when overwriting installation!\033[0m"
    read -p "Overwrite installation/uninstall the old version? (1/0) > " res
    if [ "$res" = "1" ]; then
        install
    elif [ "$res" = "0" ]; then
        rm -rf $CRASHDIR
        echo -----------------------------------------------
        $echo "\033[31m The old version files have been uninstalled!\033[0m"
        setdir
        install
    elif [ "$res" = "9" ]; then
        echo Test mode, change installation location
        setdir
        install
    else
        $echo "\033[31mInput error! Installation has been cancelled!\033[0m"
        exit 1
    fi
else
    setdir
    install
fi
