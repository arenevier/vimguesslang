Purpose
=======

Guess the language of an email to set the correct spelllang automatically.  It
works by feeding the content to aspell once for each possible language, and
choosing the one triggering the smallest number of mispelled words

Installation
============
 - Drop this file into `~/.vim/ftplugin/mail/` directory (create it if needed).
 - Make sure filetype plugins are enabled (`filetype plugin on` in your **.vimrc**)
 - Define in your .vimrc a variable `g:spell_choices` containing a comma
   separated list of languages to choose from. Otherwise, a default value of
   **fr,en** is assumed. If two languages have equal probability, the first one
   in the list is choosen.
