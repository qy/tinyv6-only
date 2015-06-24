# Script to set TinyV6 env & simply commands
#
# Usage: "source tinyv6.sh"
#
# author: Qiu Ying <qiuying@mail.nwpu.edu.cn>

######
# tinyv6 root dir
case ${BASH_SOURCE} in
    /*)
        #absolute path
        TINYOSSH=${BASH_SOURCE} ;;
    *)
        #relative path
        TINYOSSH=`pwd`/${BASH_SOURCE} ;;
esac
export TINYV6_ROOT=`dirname $TINYOSSH`

if [ ! -d $TINYV6_ROOT ]; then
    echo "TINYV6_ROOT $TINYV6_ROOT does not exist, FAIL"
    return 1
else
    echo "TINYV6_ROOT=$TINYV6_ROOT"
fi

export TINYOS_ROOT_DIR_ADDITIONAL=$TINYOS_ROOT_DIR_ADDITIONAL:$TINYV6_ROOT
