help () {
  /usr/local/scripts/listfns "$NAMESPACES/tag"
}

# This command requires two arguments: 1) a filename; 2) a tagname.
# "$#" signifies the number of arguments given to this command.
set () {
  if [[ $# == 0 || $# == 1 ]]; then
    echo "  This script requires two arguments: filename, tagname"
    exit 1;
  fi

  # -i: print the file's index number (inode).
  # -L: dereference.
  # -d: list directory entries instead of contents.
  # set REF to the inode from the pair [inode, filename].
  REF="$( ls -iLd "$1" | awk '{print $1}' )"

  # If it doesn't already exist, create a new
  # subdirectory $2 under $TAGDIR.
  if [ ! -d "$TAGDIR/$2" ]; then
    mkdir -p "$TAGDIR/$2"
  fi

  # If there isn't already a file called $REF in $TAGDIR/$S,
  # then create a softlink under that name to the file
  # in the current working directory with the name $1.
  if [ ! -f "$TAGDIR/$2/$REF" ]; then
    ln -s "$PWD/$1" "$TAGDIR/$2/$REF"
    echo "  '$1' has been tagged with '$2'"
    exit 0;
  elif [ "$REF" = "$(inode "$TAGDIR/$2/$REF")" ]; then
    echo "  '$1' has already been tagged with '$2'"
    exit 3;
  else
    echo "  Error 1: tagspace collision"
    exit 2;
  fi
}

# Echoing the output of `ls "$TAGDIR" lists the
# names of all tags currently provided.
all () {
  echo "$(ls "$TAGDIR")"
  exit 0;
}

# This command requires an argument: the name of a tag.
delete () {
  if [[ $# == 0 ]]; then
    echo '  This file requires an argument (tagname)'
    exit 1;
  else
    
    # The semicolon indicates the end of the argument list for 'echo'.
    # The backslash escapes the semicolon to prevent shell expansion.
    
    # The next two lines still require explication.
    ALL_FILES="$(find "$TAGDIR/$1" -maxdepth 1 -exec echo \; | wc -l)"
    NUM_ITEMS="$(echo "$ALL_FILES" - 1 | bc -l)"

    echo "
This tag currently applies to $NUM_ITEMS items."
    echo "Do you wish to continue? (y/n)"

    read RESPONSE

    if [[ "$RESPONSE" == 'y' ]]; then
      rm -rf "$TAGDIR/$1"
      echo "The tag '$1' has been deleted."
      exit 0;
    else
      echo "Task aborted."
    fi
  fi
}

list () {
  if [[ $# == 0 ]]; then
    echo "  An argument (tagname) is required."
    exit 1;
  else

    # -l: long-listing format.
    # '!/total/ still requires explication.
    # -F: The field-separator is '/'.
    # $NF: the total number of fields in the input record.
    # List all entries using the format: filename -> full-filepath
    echo "$(ls -l "$TAGDIR/$1" | awk '!/total/ {print $11}' | awk -F'/' '{printf("%-10s  ->  %s\n", $NF, $0)}' )"
    exit 0;
  fi
}

unset () {
  if [[ $# == 0 || $# == 1 ]]; then
    echo "  This script requires one of two patterns:"
    echo "  1) filename tagname"
    echo "  2) --all filename"
    exit 1;
  fi

  if [ -z "$TAGDIR" ]; then
    echo "  The variable TAGDIR has not been set to '$HOME/.tags' or exported"
    exit 2;
  fi

  # REF is set to the inode of filename
  #REF="$( ls -iLd "$1" | awk '{print $1}' )"

  if [[ "$1" = --all ]]; then
    REF="$( ls -iLd "$2" | awk '{print $1}' )"
    find "$TAGDIR" -name "$REF" -delete
    echo "  All tags for '$2' have been deleted"
    exit 0;
  else
    REF="$( ls -iLd "$1" | awk '{print $1}' )"
    rm "$TAGDIR/$2/$REF"
    echo " The tag '$2' no longer applies to '$1'"
    exit 0;
  fi
}
