#

#Text Summarization using Sentence Centrality 
#

#readFile function asks the user to enter the file name to read the sentences from, then checks that it exits and that is a file not a directory for example
readFile () {
  while true
  do
    echo "Please enter the name of the file you want to get the sentences from:"
    read fileName
    if [ ! -e "$fileName" ] 
    then
      echo "------"
      echo "File dosn't exist!, would you like to type another file name or teminate? "
      echo "If you want to enter file name please enter (y) but if you want to terminate, enter (t): "
      read flag
      if [ "$flag" = "y" ]
      then 
      echo ""
        continue
      else 
        echo "-------------------------"
        echo "Good Bye ^-^"
        exit 1
      fi
	  
	else  
      if [ ! -f "$fileName" ] 
      then
        echo "------"
        echo "It's not a file to read from!, would you like to try another name (y) or terminate (t)? "
        echo "please enter (y) or (t):  "
        read flag
        if [ "$flag" = "y" ]
        then 
        echo ""
          continue
        else 
          echo "-------------------------"
          echo "Good Bye ^-^"
          exit 1
        fi
      else
        echo "-------------------------"
        echo "Done reading"
        cat "$fileName" > tempfile.txt
        break
	  fi
    fi
 done
}

#----------------------
#function asks the user to enter the summary ratio and checks that it is a number not an alphabetic
readRatio() {
  while true
  do
    echo "Enter summery ratio: "
    read summeryRatio
    case $summeryRatio in 
    [a-zA-Z]*)
      echo "------"
      echo "This is not a number!, would you like to try another value(enter v) or teminate(enter t)? "
      read flag
      if [ "$flag" = "v" ]
      then 
      echo ""
        continue
      else 
        echo "-------------------------"
        echo "Good Bye ^-^"
        exit 1
      fi   ;;
      
      [0-9]* )
      if [  "$summeryRatio" -gt 1 -o "$summeryRatio" -lt 0  ] 
      then
        echo "------"
        echo "Wrong input, Please enter a value between 0 and 1"
        continue
        
      else
        echo "-------------------------"
        echo "valid ratio"
        break  
      fi ;;
     esac
  done
}

#----------------------
#function tokenize Sentence based on ( . ! ? ) punctuation marks and store it in an array (called lines) also to get number of sentences that we have.
tokenization() {
    cat tempfile.txt | tr -s '.!?' "\n" > temp2.txt
    IFS=$'\n' read -d '' -r -a lines < temp2.txt
    cp temp2.txt tempfile.txt
    numberOfSentences=$(echo "${#lines[@]}")
}

#----------------------
#convertToLowerCase function as it names indicates it changes the alphabets to their lower case
convertToLowerCase () {
  for((i=0 ; i<numberOfSentences ; i++))
  do
    lines[i]=$( echo ${lines[i]} | tr "[A-Z]" "[a-z]")
  done  
}

#----------------------
#removeStopWords function as it names indicates it remove stop words from sentences. Stop Words are words, which do not contain important information
declare -a stopWords=("i" "a" "an" "as" "at" "the" "by" "in" "for" "of" "on" "that")
removeStopWords () {
 for i in "${stopWords[@]}"
  do
     for((j=0 ; j < numberOfSentences ; j++))
     do
       lines[j]=$( echo ${lines[j]} | sed "s/\<$i\>//g")
     done
  done
}

#----------------------
#removeDuplication function as it names indicates it Remove the duplication of words from sentences. In other words, each word will appear once per sentence.
removeDuplication () {
  for ((i=0 ; i<numberOfSentences ; i++))
  do 
       lines[i]=$(echo ${lines[i]} | sed ":s;s/\(\<\S*\>\)\(.*\)\<\1\>/\1\2/g;ts")
  done
}

#----------------------
#similarityAndCentrality function as it names indicates it calculated the similarity between each pair of sentences that we have in the lines array, and compute the centrality of each sentence.
similarityAndCentrality () {
  for ((i=0 ; i<numberOfSentences ; i++))
  do 
       local centra=0
       IFS=' ' read -r -a words0 <<< "${lines[i]}" 
        
       for((j=0 ; j<numberOfSentences ; j++))
         do 
         IFS=' ' read -r -a words1 <<< "${lines[j]}"
         local sumSim=0
         for n in "${words0[@]}"
           do
           for m in "${words1[@]}"
           do
              if [ "$n" == "$m" ]
                then 
                  sumSim=$( expr $sumSim + 1 ) #intersection
              else 
                continue
              fi
             done
        done
        numw0=$(echo "${lines[i]}" | wc -w) 
        numw1=$(echo "${lines[j]}" | wc -w)
        numwordsall=$(expr $numw0 + $numw1)
        union=$(expr $numwordsall - $sumSim)  #union
        sim=$(echo 4 k  $sumSim $union / p | dc) #similarity of each sentence
        centra=$(echo 4 k $centra $sim + p | dc)  #centrality if each centence
       done
       centrality[$i]=$centra
  done

}

#----------------------
#sortByCentrality function it sortes sentences based on their centrality score and stor them in temp22.txt.
sortByCentrality () {
  #concate centrality with its sentences in one line
  for((i=0 ; i<numberOfSentences ; i++))
  do
      cent="${centrality[$i]}"
      line="${lines[i]}"
      concatline="${cent} ${line}"
      #echo $concatline
      centrality[$i]=$concatline
   done
   
   #print the array contain centrality and sentences to temp2.txt
   printf "%s\n" "${centrality[@]}" > temp2.txt
   #sort it descending
   sort -k1 -rn temp2.txt > temp22.txt 
}

#----------------------
#writeFile function to write top ranked sentences that have been selected based on the summary ratio entered by the user beforeand then written to a file named summary.txt.
writeFile () {
  #to find number of sentences that have topranked
   numberOfS=$(echo 1 k $numberOfSentences $summeryRatio \* p | dc)
   numberOfS=$(echo ${numberOfS%.*})     #convert from float to int 
   
   cat temp22.txt | cut --complement -d " " -f 1 > temp2.txt   #take just the sentences part from temp22.txt file
   IFS=$'\n' read -d '' -r -a descLines < temp2.txt     # put the sentences in an array
   
   declare -a summary    #new array to store top ranked sentences
   for((i=0 ; i<numberOfS ; i++))
   do
    summary[$i]="${descLines[i]}"
   done
   
  
   IFS=$'\n' read -d '' -r -a lineso < tempfile.txt

    
   for((i=0 ; i<numberOfS ; i++))
   do
      IFS=' ' read -r -a words0 <<< "${summary[$i]}"
      numw=$(echo "${summary[$i]}" | wc -w)
       for((j=0 ; j<numberOfSentences ; j++))
       do 
            IFS=' ' read -r -a words1 <<< "${lineso[j]}"
            local numsw=0
         
         for n in "${words0[@]}"
           do
           for m in "${words1[@]}"
           do
           shopt -s nocasematch
           case "$m" in 
           "$n" )
                  numsw=$( expr $numsw + 1 ) ;;
            * )
                continue ;;
           esac
             done
        done
        if [ $numsw -ge $numw ]    
        then 
           summary[$i]="${lineso[j]}"
        else
          continue
        fi
        
     done
   done
   printf "%s\n" "${summary[@]}" > summary.txt
}

#####################################################################################################
echo "          Welcome to the program of Text Summarization using Sentence Centrality Analyzer  " 
echo "          -------------------------------------------------------------------------------  "
readFile 
echo "-------------------------"
readRatio
echo "-------------------------"
tokenization
convertToLowerCase
removeStopWords
removeDuplication
declare -A centrality  #declare an array
similarityAndCentrality
sortByCentrality
writeFile
echo "-------------------------------------------"
echo "Have a good day ^-^"
