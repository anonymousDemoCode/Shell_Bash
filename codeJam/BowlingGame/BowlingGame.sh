#/bin/bash

set -u
#set -x

declare -i lineNum=1

declare -r FILENAME="/dev/shm/temp.$$"
dos2unix -n $1 $FILENAME &>/dev/null
if [[ ! -e "$FILENAME" && ! -r "$FILENAME" ]]; then echo "Create temporary file($FILENAME) failed."; exit 1;fi

# count of ball 1, count of ball 2, and reward, final count
declare -a countArray=()
declare -r countBall1Idx=0
declare -r countBall2Idx=1
declare -r rewardIdx=2
declare -r countFinalIdx=3
declare -r ElementCnt=4

declare -i round=0
declare -r MaxRound=10
declare -i ballIdx=0

#printf "$LINE\r\n"

while read LINE;do
    if [ $lineNum -eq 1 ]; then ((lineNum = lineNum + 1));continue; fi
    ((lineNum = lineNum + 1)); #printf "%4d :  " "$lineNum";

    # clean for next game
    round=0
    ballIdx=0
    for (( i = 0; i <= MaxRound; i++ ));do
        (( countArray[$ElementCnt * $i + $countBall1Idx] = 0 ))
        (( countArray[$ElementCnt * $i + $countBall2Idx] = 0 ))
        (( countArray[$ElementCnt * $i + $rewardIdx] = 0 ))
        (( countArray[$ElementCnt * $i + $countFinalIdx] = 0 ))
    done

    #echo $LINE
    #printf "%4s :  " ""
    for (( idx = 0; idx < ${#LINE}; idx++ )); do
        case "Y${LINE:$idx:1}" in
            Y\| )
                #printf "Character |\n"
                # next round init
                if [ $round -lt 10 ];then
                    (( round = round + 1 ))
                    (( ballIdx = 0 ))
                fi
            ;;
            # Y? )
                # #printf "%s" "${LINE:$idx:1}"
                # #printf "Unknown character!\n"
                # if [ "$countArray[$ElementCnt * $round + $rewardIdx]" != "0" ]; then
                    # (( countArray[$ElementCnt * $round + $rewardIdx] = countArray[3 * $round + $rewardIdx] - 1 ))
                # fi
                # (( ballIdx = ballIdx + 1 ))
            # ;&
            YX )
                (( countArray[$ElementCnt * $round] = 10 ))
                (( countArray[$ElementCnt * $round + $rewardIdx] = 2 ))
                (( ballIdx = ballIdx + 1 ))
                #printf "Character X\n"
            ;;
            Y\/ )
                #printf "Character /\n"
                if [ "$ballIdx" = "0" ];then
                   echo "Wrong input the char / should be in the second char of a round.";
                fi
                (( countArray[$ElementCnt * $round + 1 ] = 10 - countArray[$ElementCnt * $round + 0 ] ))
                (( countArray[$ElementCnt * $round + $rewardIdx] = 1 ))
            ;;
            Y\: | Y\- )
                #printf "Character :\n"
                # miss, no count
                (( countArray[$ElementCnt * $round + $ballIdx ] = 0 ))
                (( ballIdx = ballIdx + 1 ))
            ;;
            Y[0-9] )
                #printf "Character 0-9\n"
                (( countArray[$ElementCnt * $round + $ballIdx ] = ${LINE:$idx:1} ))
                (( ballIdx = ballIdx + 1 ))
            ;;
            Y? )
                #printf "%s" "${LINE:$idx:1}"
                printf "Unknown character(${LINE:$idx:1})!\n"
            ;;
        esac
    done
    #echo ""

    # clean the last reward of the extra round
    (( countArray[$ElementCnt * $MaxRound + $rewardIdx] = 0 ))
    
    for (( i = 0; i < MaxRound; i++ ));do
        if [ "${countArray[$ElementCnt * $i + $rewardIdx]}" = "2" ];then
            if [ "${countArray[$ElementCnt * ($i+1) + $rewardIdx]}" = "2" ];then
                if [ "${countArray[$ElementCnt * ($i+2) + $rewardIdx]}" = "2" ];then
                    (( countArray[$ElementCnt * $i + $countFinalIdx] = 30 ))
                else
                    (( countArray[$ElementCnt * $i + $countFinalIdx] = 20 + ${countArray[$ElementCnt * ($i+2) + $countBall1Idx]} ))
                fi
            else
                (( countArray[$ElementCnt * $i + $countFinalIdx] = 10 + ${countArray[$ElementCnt * ($i+1) + $countBall1Idx]} + ${countArray[$ElementCnt * ($i+1) + $countBall2Idx]} ))
            fi
        elif [ "${countArray[$ElementCnt * $i + $rewardIdx]}" = "1" ];then
            if [ "${countArray[$ElementCnt * ($i+1) + $rewardIdx]}" = "2" ];then
                (( countArray[$ElementCnt * $i + $countFinalIdx] = 20 ))
            else
                (( countArray[$ElementCnt * $i + $countFinalIdx] = 10 + ${countArray[$ElementCnt * ($i+1) + ${countBall1Idx}]} ))
            fi
        else
            (( countArray[$ElementCnt * $i + $countFinalIdx] = ${countArray[$ElementCnt * $i + $countBall1Idx]} + ${countArray[$ElementCnt * $i + $countBall2Idx]} ))
        fi
    done
    
    for (( i = 0; i < MaxRound; i++ ));do
        #printf "%4d" ${countArray[$ElementCnt * $i + $countFinalIdx]}
        (( countArray[$ElementCnt * $MaxRound + $countFinalIdx] += ${countArray[$ElementCnt * $i + $countFinalIdx]} ))
    done
    
    #printf "\n"

    printf "%d\n" "${countArray[$ElementCnt * $MaxRound + $countFinalIdx]}">>log

done < $FILENAME
