#!/bin/bash
x=0
#Set the initial range, count the amount of quotes we have.
setRange=$(mysql quotes -u root --password=password -sse "select count(*) from quotes")
#Function email
email(){
        #Just keep doing it, until we find a quote.
        while [ 1 ]; do
        #while [ "$x" -lt "$setRange" ]; do while [ "$x" -lt "50" ]; do let x++
	#Create an array of unused quotes with their IDs http://stackoverflow.com/questions/17774405/bash-sql-query-outputs-to-variable
                read -ra vars <<< $(mysql quotes -u root --password=password -sse "SELECT id FROM quotes WHERE used = 0 and donotuse = 0")
                                for i in "${vars[@]}" ; do
                                #Put the unused quotes ID into yet another array
                                unUsedQuotes+=("$i")
                done
                if [ -z $unUsedQuotes ] ; then
                        #If the array is blank, let's reset!
                        #mysql quotes -u root --password=password -sse "UPDATE quotes set used = 1 where id=$number"
                        #echo "Hey! The email script didn't reset properly"
			echo "Hey! The email script didn't reset properly" | mail kevin@hxrsmurf.info -s "QoTD ERROR" -a "From: root@hxrsmurf.info"
			break
                else
                        #Pick a random number of said array above http://stackoverflow.com/questions/2388488/select-a-random-item-from-an-array
                        number=${unUsedQuotes[$RANDOM % ${#unUsedQuotes[@]} ]}
                        #Mark the quote used/read/sent.
                        mysql quotes -u root --password=password -sse "UPDATE quotes set used = 1 where id=$number"

			#No point in sleeping, since with a variation of 50 out of the unused array
			#There was a .05% chance it'd be duplicate. sleep 1 Get the person and the quote from that random number

                        person=$(mysql quotes -u root --password=password -sse "select person from quotes where id=$number")
                        quote=$(mysql quotes -u root --password=password -sse "select quote from quotes where id=$number")

                        #Increase the count for fun.
                        mysql quotes -u root --password=password -sse "UPDATE quotes set count = count + 1 where id=$number"

                        #Prepare e-mail quote
                        equote="$person: $quote"

			equoteLength="`expr length "$equote"`"
			#echo $equoteLength

                        if [ $equoteLength -ge 140 ] ; then
                                tequote="`expr substr "$equote" 1 137`"
                                tequote="$tequote..."

                                tequote2="`expr substr "$equote" 138 $equoteLength`"
                        else
                                #NO need to cut
				tequote=$equote
                        fi

                        #Send the e-mail

			echo $tequote | mail quotes-text@hxrsmurf.info -a "From: qotd@hxrsmurf.info"

			if [ -z $tequote2 ] ; then
				echo "Empty"
			else
				echo $tequote2 | mail quotes-text@hxrsmurf.info -a "From: qotd@hxrsmurf.info"
			fi

                        #echo $tequote

			echo $equote | mail quotes-email@hxrsmurf.info -s "QotD for $(date "+%A, %B %d")" -a "From: qotd@hxrsmurf.info"
			#echo $equote | mail kevin@hxrsmurf.info -s "QotD for $(date "+%A, %B %d")" -a "From: qotd@hxrsmurf.info"
			#echo $equote
			#facebook_quote
                        break
                fi
        done
}


#Check if there are any unused quotes available.
#If they are, let's do the email function If not, let's RESET the database and try again.

anyLeft=$(mysql quotes -u root --password=password -sse "SELECT id FROM quotes WHERE used = 0 and donotuse = 0")
if [ -z "$anyLeft" ] ; then
        mysql quotes -u root --password=password -sse "UPDATE quotes set used = 0 where 1"
	#echo "Hey, I'm resetting"
        echo "Hey, I'm resetting" | mail kevin@hxrsmurf.info -s "Resetting Quotes" -a "From: root@hxrsmurf.info"
        email
else
        email
fi
