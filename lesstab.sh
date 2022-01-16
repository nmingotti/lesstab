#!/bin/sh 

# TODO
# . generico command in input 
# . manage the case of window resize 
# . IMPROVEMENT. forzare lo schermo superiore ad una sola riga solo se la dimensione 
#                dello schermo è effettivamente cambiata.

# . FOR DEBUG, uncomment next line 
# set -x 

SESSION="lesst"
# INPUT=/proc/$$/fd/0

# . create the pipe files to comunicate data to subprocesses 
PIPE_HEAD=/tmp/$SESSION-head
PIPE_TAIL=/tmp/$SESSION-tail 
rm $PIPE_HEAD
rm $PIPE_TAIL
mkfifo $PIPE_HEAD
mkfifo $PIPE_TAIL

# . if there is around a session with my name kill it 
tmux list-sessions 2> /dev/null | grep $SESSION  
alive_q=$?
if [ $alive_q = 0 ]; then 
    tmux kill-session -t $SESSION 2> /dev/null
fi 


# . in un terminale dare questo
tmux new-session -s $SESSION -n 'w1' -d 

# . aprire altro terminale e controllare 'test1'
# . splittare verticalmente test1
tmux split-window -t $SESSION:0

# . dire che test1:0.0 (session:test1, window:0, pane:0) è di altezza 4 righe
# tmux resize-pane -y 1 -t $SESSION:0.0
tmux resize-pane -y 1 -t $SESSION:0.0

# . Metto l'header della tabella (di pa aux) nel pane 0
# tmux send-key -t $SESSION:0.0 "ps aux | head -n 1 | awk '{printf \"%s\", \$0} END {getline name < \"/dev/tty\"}' " C-m

tmux send-key -t $SESSION:0.0 "cat $PIPE_HEAD | head -n 1 | awk '{printf \"%s\", \$0} END {getline name < \"/dev/tty\"}' " C-m


# . Ogni secondo forza il pane in alto alla dimensione di una rige
#   Questo serve perchè la dimensione dello schermo potrebbe essere modficata.
#   dall'utente fancedo saltare il parametro fissato anteriormente.
#  
(while `true`; do
     # . wait a bit 
     sleep 1 
     # . if the tmux father session isnt'alive quit this process 
     tmux list-sessions 2> /dev/null | grep $SESSION 
     aliveq=$?
     # echo "alive: $aliveQ"
     if [ $aliveq = "1" ] ; then 
	 break 
     else 
	 # . if the session is alive keep the top part at one line 
	 tmux resize-pane -y 1 -t $SESSION:0.0 2> /dev/null
     fi
done 
) & 

# . metto il body della tabella (di ps aux) nel pane 1
# .. tail -n +2 mostra tutte le righe a partire dalla seconda.
# . when we exit 'less' the tmux session $SESSION dies 
# tmux send-key -t $SESSION:0.1 "ps aux | tail -n +2 | less ; tmux kill-session -t $SESSION " C-m
tmux send-key -t $SESSION:0.1 "cat $PIPE_TAIL | tail -n +2 | less ; tmux kill-session -t $SESSION " C-m

# PROBLEMA. tmuxh deve accedere al parent process terminal
# quindi gli servono 
# . entro nella sessione 
# tmux attach -t $SESSION 

# . duplicate stdin and send it to both pipes 
#   "tee" locks untill both pipes are red, therefore it mush 
#    be sent do a child process 
tee $PIPE_HEAD $PIPE_TAIL > /dev/null   




