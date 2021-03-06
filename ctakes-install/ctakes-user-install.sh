#!/bin/bash

#TODO: Add better error handling/troubleshooting.

### Script Beginning ###

PWD=$(pwd)
ORIG=$(echo $PWD/$(dirname $0) | sed 's#/\.##')
cTAKES_HOME="$ORIG/apache-ctakes-4.0.0"

#FIXME: Fix output formatting
progressfilt ()
{
    local flag=false c count cr=$'\r' nl=$'\n'
    while IFS='' read -d '' -rn 1 c
    
    do
        if $flag
        then
            printf '%c' "$c"
        else
            if [[ $c != $cr && $c != $nl ]]
            then
                count=0
            else
                ((count++))
                if ((count > 1))
                then
                    flag=true
                fi
            fi
        fi
    done
}

printf "\n\033[92m\u0F36\033[0m Install directory: $cTAKES_HOME \n"

### Checking for dependencies ###

printf "\n\033[92m\u0F36\033[0m Checking for dependencies...\n"

# Jave Check #

if type -p java 2>&1 >/dev/null; then
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then     
    _java="$JAVA_HOME/bin/java" 2>&1 >/dev/null
else
    printf "\n  \u2573 Java wasn't found. Please install Java 1.8 or greater and try again!"
	exit 1
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    if [[ "$version" > "1.8" ]] || [[ "$version" > "10.0.0" ]]; then
        printf "\n  \033[92m\u2713\033[0m Java 1.8 or greater is installed!\n"
    else         
        printf "\n  \033[91m\u2573\033[0m Current Java version is $version please upgrade to Java 1.8 or greater!\n"
		exit 1
    fi
fi

# Warn if install exists #

if [ -d "$CTAKES_HOME" ]; then
	printf "\n  \033[91m\u2573\033[0m cTakes install already exists!\n\n"
	exit 1
fi

# Download cTAKES user install file linux #
if [ ! -d "$CTAKES_HOME" ]; then
	printf "\n\033[92m\u0F36\033[0m Downloading: apache-ctakes-4.0.0-bin.tar.gz\n\n"

    wget --progress=bar:force http://www-eu.apache.org/dist/ctakes/ctakes-4.0.0/apache-ctakes-4.0.0-bin.tar.gz -P "$ORIG/tmp/" 2>&1 | progressfilt
    tar -xvf $ORIG/tmp/apache-ctakes-4.0.0-bin.tar.gz -C $ORIG/$CTAKES_HOME
fi

# Get resource files #

printf "\n\033[92m\u0F36\033[0m Downloading: ctakes-resources-4.0.0-bin.zip\n\n"
cd $ORIG/tmp
wget --progress=bar:force http://sourceforge.net/projects/ctakesresources/files/ctakes-resources-4.0-bin.zip -P "$ORIG/tmp/" 2>&1 | progressfilt

printf "\033[92m\u0F36\033[0m Unzipping and moving resource files...\n\n"
unzip ctakes-resources-4.0-bin.zip
cp -R $ORIG/tmp/resources/* $ORIG/apache-ctakes-4.0.0/resources
rm -r $ORIG/tmp/

# Update UMLS Credentials #
if [ ! -f $PWD/umls.sh ]; then
    read -r -p "
    ༶ Add UMLS credentials? [y/N] " response
    response=${response,,}

    cd ../

    if [[ "$response" =~ ^(yes|y)$ ]]; 
    then
        touch $PWD/umls.sh
        printf "#!/bin/bash \n\nUMLS_USERNAME=\"SAMPLE_USER\"\nUMLS_PASSWORD=\"SAMPLE_PASSWORD\"\n\nexport UMLS_USERNAME\nexport UMLS_PASSWORD" >> $PWD/umls.sh
        chmod +x $PWD/umls.sh

        read -r -p "༶ Username: `echo $'\n> '`" username
        username=${username,,}

        set_password() {

            read -rs -p "༶ Password: `echo $'\n> '`" password_1
            password_1=${password_1}

            read -rs -p "`echo $'\r'`༶ Verify Password: `echo $'\n> '`" password_2
            password_2=${password_2}

            if [[ $password_1 = $password_2 ]];then

               sed -i -e "s/SAMPLE_USER/$username/g" $PWD/umls.sh
               sed -i -e "s/SAMPLE_PASSWORD/$password_1/g" $PWD/umls.sh

            else
                printf "\n༶ Password mismatch try again...\n"
                set_password
            fi
        }
        set_password
        printf "\n\033[92m\u0F36\033[0m UMLS credentials updated!\n"
    else
        printf "\n\033[92m\u0F36\033[0m No worries you can add them manually later!\n"
    fi
fi
printf "\n\u0FC9 DONE!\n\n"