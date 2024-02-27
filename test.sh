while getopts "r:" flag > /dev/null 2>&1
do
    case ${flag} in
        r) BOOT="${OPTARG}" ;;
        *) break;; 
    esac
done

echo $BOOT