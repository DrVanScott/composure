#!/bin/bash
# Composure - don't fear the UNIX chainsaw...
# by erichs, 2012

# these are a set of light-hearted shell functions that aim to make
# programming the shell easier and more intuitive

# latest source available at http://git.io/composure

source_composure ()
{
    if [ -z "$EDITOR" ]
    then
      export EDITOR=vi
    fi

    if $(tty -s)    # is this a TTY?
    then
      bind '"\C-j": edit-and-execute-command'
    fi

    cite ()
    {
        about () { :; }
        about creates a new meta keyword for use in your functions
        local keyword=$1
        for keyword in $*; do
            eval "function $keyword { :; }"
        done
    }

    cite about param example

    draft ()
    {
        about wraps last command into a new function
        param 1: name to give function
        example $ ls
        example $ draft list
        example $ list
        local func=$1
        eval 'function ' $func ' { ' $(fc -ln -1) '; }'
        gitonlyknows $func draft
    }

    gitonlyknows ()
    {
        about store function in ~/.composure git repository
        param 1: name of function
        param 2: operation label
        example $ gitonlyknows myfunc 'scooby-doo version'
        example stores your function changes with:
        example master 7a7e524 scooby-doo version myfunc
        local func=$1
        local operation="$2"

        if git --version >/dev/null 2>&1
        then
            write $func > ~/.composure/$func.sh
            (
                cd ~/.composure
                git add --all .
                git commit -m "$operation $func"
            )
        fi
    }

    metafor ()
    {
        about prints function metadata associated with keyword
        param 1: function name
        param 2: meta keyword
        example $ metafor reference example
        local func=$1 keyword=$2
        write $func | sed -n "s/^ *$keyword \([^([].*\)$/\1/p"
    }

    reference ()
    {
        about displays help summary for all functions, or help for specific function
        param 1: optional, function name
        example $ reference
        example $ reference metafor

        printline ()
        {
            local metadata=$1 leftcol=${2:- } rightcol

            if [[ -z "$metadata" ]]
            then
                return
            fi

            OLD=$IFS; IFS=$'\n'
            for rightcol in $metadata
            do
                printf "%-20s%s\n" $leftcol $rightcol
            done
            IFS=$OLD
        }

        help ()
        {
            local func=$1

            local about="$(metafor $func about)"
            printline "$about" $func

            local params="$(metafor $func param)"
            if [[ -n "$params" ]]
            then
                echo "parameters:"
                printline "$params"
            fi

            local examples="$(metafor $func example)"
            if [[ -n "$examples" ]]
            then
                echo "examples:"
                printline "$examples"
            fi
        }

        if [[ -n "$1" ]]
        then
            help $1
        else
            for func in $(compgen -A function); do
                local about="$(metafor $func about)"
                printline "$about" $func
            done
        fi

        unset help printline
    }

    revise ()
    {
        about loads function into editor for revision
        param name of function or functions, separated by spaces
        example $ revise myfunction
        example $ revise func1 func2 func3

        local temp=$(mktemp /tmp/revise.XXXX)

        write $* > $temp
        $EDITOR $temp
        eval "$(cat $temp)"

        for func in $*
        do
            gitonlyknows $func revise
        done
        rm $temp
    }

    write ()
    {
      about prints function declaration to stdout
      param name of function or functions, separated by spaces
      example $ write myfunction
      example $ write func1 func2 func3 > ~/funcs.sh
      local func
      for func in $*
      do
          # sed-fu: trim trailing semicolons from declare -f,
          # but leave double-semi's (ie case blocks) intact
          declare -f $func | sed  "s/;;$/;;;/;s/^\(.*\);$/\1/"
          echo
      done
    }


}

install_composure ()
{
    echo 'stay calm. installing composure elements...'

    # find our absolute PATH
    SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]
    do
        SOURCE="$(readlink "$SOURCE")"
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

    # vim: automatically chmod +x scripts with #! lines
    done_previously () { [ ! -z "$(grep BufWritePost | grep bin | grep chmod)" ]; }

    if [ -f ~/.vimrc ] && ! $(<~/.vimrc done_previously)
    then
      echo 'vimrc: adding automatic chmod+x for files with shebang (#!) lines...'
      echo 'au BufWritePost * if getline(1) =~ "^#!" | if getline(1) =~ "/bin/" | silent execute "!chmod a+x <afile>" | endif | endif' >> ~/.vimrc
    fi

    # source this file in your startup: .bashrc, or .bash_profile
    local done=0
    done_previously () { [ ! -z "$(grep source | grep $DIR | grep composure)" ]; }

    [ -f ~/.bashrc ] && $(<~/.bashrc done_previously) && done=1
    ! (($done)) && [ -f ~/.bash_profile ] && $(<~/.bash_profile done_previously) && done=1

    if ! (($done))
    then
      echo 'sourcing composure from .bashrc...'
      echo "source $DIR/$(basename $0)" >> ~/.bashrc
    fi

    # prepare git repo
    if git --version >/dev/null 2>&1
    then
        if [ ! -d ~/.composure ]
        then
            (
                echo 'creating git repository for your functions...'
                mkdir ~/.composure
                cd ~/.composure
                git init
                echo "composure stores your function definitions here" > README.txt
                git add README.txt
                git commit -m 'initial commit'
            )
        fi
    fi

    echo 'composure installed.'
}

if [[ "$BASH_SOURCE" == "$0" ]]
then
  install_composure
else
  source_composure
  unset install_composure source_composure
fi

: <<EOF
License: The MIT License

Copyright © 2012 Erich Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
