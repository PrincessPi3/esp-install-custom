subprocess() {
    echo -e "\nChanging ESPBAUD\n\t1: 9600\n\t2: 115200\n\t3: 230400\n\t4: 460800\n\t5: 1152000\n\t6: 1500000\n\nEnter Selection: "
    read baudRate
    echo -e "\n"
    case $baudRate in
    1) selection=9600 ;;
    2) selection=115200 ;;
    3) selection=230400 ;;
    4) selection=460800 ;;
    5) selection=1152000 ;;
    6) selection=1500000 ;;
    esac

    return $selection
}

subprocess
ret=$?

export ESPBAUD=$ret

echo "\nBaudrate set to $ESPBAUD\n"
echo "\nAll done :3\n"