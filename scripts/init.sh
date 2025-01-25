#!/bin/sh
# Copyright (C) Juewuy

version=1.9.2alpha6

setdir() {
    dir_avail() {
        df $2 $1 | awk '{ for(i=1;i<=NF;i++){ if(NR==1){ arr[i]=$i; }else{ arr[i]=arr[i]" "$i; } } } END{ for(i=1;i<=NF;i++){ print arr[i]; } }' | grep -E 'Ava|Available' | awk '{print $2}'
    }
    set_usb_dir() {
        echo -e "Please choose installation directory"
        du -hL /mnt | awk '{print " "NR" "$2"  "$1}'
        read -p "Please enter the corresponding number > " num
        dir=$(du -hL /mnt | awk '{print $2}' | sed -n "$num"p)
        if [ -z "$dir" ]; then
            echo -e "\033[31mInput error! Please reset!\033[0m"
            set_usb_dir
        fi
    }
    set_asus_dir() {
        echo -e "Please choose the USB directory"
        du -hL /tmp/mnt | awk '{print " "NR" "$2"  "$1}'
        read -p "Please enter the corresponding number > " num
        dir=$(du -hL /tmp/mnt | awk '{print $2}' | sed -n "$num"p)
        if [ ! -f "$dir/asusware.arm/etc/init.d/S50downloadmaster" ]; then
            echo -e "\033[31mDownload master startup file not found: $dir/asusware.arm/etc/init.d/S50downloadmaster, please check settings!\033[0m"
            set_asus_dir
        fi
    }
    set_cust_dir() {
        echo -----------------------------------------------
        echo 'Available paths Remaining space:'
        df -h | awk '{print $6,$4}' | sed 1d
        echo 'The path must be in / format. Note that files written to virtual memory (/tmp,/opt,/sys...) will disappear after reboot!!!'
        read -p "Please enter the custom path > " dir
        if [ "$(dir_avail $dir)" = 0 ]; then
            echo "\033[31mPath error! Please reset!\033[0m"
            set_cust_dir
        fi
    }
    echo -----------------------------------------------
    if [ -n "$systype" ]; then
        [ "$systype" = "Padavan" ] && dir=/etc/storage
        [ "$systype" = "mi_snapshot" ] && {
            echo -e "\033[33mDetected Xiaomi official system, please choose installation location\033[0m"
            [ "$(dir_avail /data)" -gt 256 ] && echo " 1 Install to /data directory (recommended, supports soft-solidification function)"
            [ "$(dir_avail /userdisk)" -gt 256 ] && echo " 2 Install to /userdisk directory (recommended, supports soft-solidification function)"
            echo " 3 Install to custom directory (not recommended, do not use if unknown!)"
            echo " 0 Exit installation"
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
            echo -e "\033[33mDetected Asus firmware, please choose installation method\033[0m"
            echo -e " 1 Install based on USB device (limited to firmware before Sep 2023, must insert \033[31many\033[0m USB device)"
            echo -e " 2 Install based on startup script (only supports Merlin and some non-koolshare official modified firmware)"
            echo -e " 3 Install based on USB+Download Master (supports all firmware, limited to ARM devices, must insert USB or external hard drive)"
            echo -e " 0 Exit installation"
            echo -----------------------------------------------
            read -p "Please enter the corresponding number > " num
            case "$num" in
            1)
                read -p "Install the script to USB storage/system flash? (1/0) > " res
                [ "$res" = "1" ] && set_usb_dir || dir=/jffs
                usb_status=1
                ;;
            2)
                echo -e "If it cannot start normally, please reinstall using USB method!"
                sleep 2
                dir=/jffs
                ;;
            3)
                echo -e "Please install and enable Download Master in the router web backend first, then choose the external storage directory!"
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
        echo -e "\033[33mInstalling ShellCrash requires at least about 1MB of disk space\033[0m"
        echo -e " 1 Install in \033[32m/etc directory\033[0m (suitable for root users)"
        echo -e " 2 Install in \033[32m/usr/share directory\033[0m (suitable for Linux systems)"
        echo -e " 3 Install in \033[32mcurrent user directory\033[0m (suitable for non-root users)"
        echo -e " 4 Install in \033[32mexternal storage\033[0m"
        echo -e " 5 Manually set the installation directory"
        echo -e " 0 Exit installation"
        echo -----------------------------------------------
        read -p "Please enter the corresponding number > " num
        if [ -z $num ]; then
            echo Installation canceled
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
            echo -----------------------------------------------
            echo 'Available paths Remaining space:'
            df -h | awk '{print $6,$4}' | sed 1d
            echo 'The path must be in / format. Note that files written to virtual memory (/tmp,/opt,/sys...) will disappear after reboot!!!'
            read -p "Please enter the custom path > " dir
            if [ -z "$dir" ]; then
                echo -e "\033[31mPath error! Please reset!\033[0m"
                setdir
            fi
        else
            echo Installation canceled!!!
            exit 1
        fi
    fi

    if [ ! -w $dir ]; then
        echo -e "\033[31mNo write permissions for $dir directory! Please reset!\033[0m" && sleep 1 && setdir
    else
        echo -e "Target directory \033[32m$dir\033[0m remaining space: $(dir_avail $dir -h)"
        read -p "Confirm installation? (1/0) > " res
        [ "$res" = "1" ] && CRASHDIR=$dir/ShellCrash || setdir
    fi
}
setconfig() {
    #Parameter 1 represents variable name, parameter 2 represents variable value, parameter 3 is the file path
    [ -z "$3" ] && configpath=${CRASHDIR}/configs/ShellCrash.cfg || configpath="${3}"
    [ -n "$(grep "${1}=" "$configpath")" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >>$configpath
}
