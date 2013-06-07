#shell

So I finally got fed up of cmd. even with the epic [clink](https://code.google.com/p/clink/), cmd just sucks. 

You know what doesnt suck? NodeJS. CoffeeScript. These things don't suck at all. So lets make a replacement shell in those. "Isnt that a really bad idea? Aren't all the awesome unix shells like bash and zsh written in C?" Why yes, it probably is. This is probably a horrible idea, but for now, its working better than cmd for my uses.

It hasn't even got feature parity with cmd yet, its missing a load of stuff, and relies on the existence of a lot of the unix core utils to fill in the blanks. Thank god for MSYSGit eh? 

Hopefully as I dogfood this, it will get better. Currently we have bash-ish path completion and input, customizable prompts, and pluggable commands and completions. Oh, and persistent history. And just about nothing else. 