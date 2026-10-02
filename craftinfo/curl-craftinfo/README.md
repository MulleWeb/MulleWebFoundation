# curl-craftinfo

Craftinfo for mulle-sde to build [curl](//github.com/<|GITHUB_USER|>/curl)

``` bash
mulle-sde dependency add --github <|GITHUB_USER|> curl
mulle-sde dependency mark curl singlephase
# mulle-sde dependency set curl aliases curl-other
# mulle-sde dependency set curl include curl-other.h
# mulle-sde environment --global set MULLE_CRAFT_USE_SCRIPTS curl-build
```

## Tips

* If you want to define `CFLAGS` use `definition/set/append/CFLAGS` instead of `definition/set/CFLAGS` so that you can still add flags with the environment variable `CFLAGS`. Or use `mulle-sde dependency craftinfo  set --append curl CFLAGS "-DX=0`
* use `CPPFLAGS` instead of `CFLAGS` to match C++, C and Objective-C
* you can use `definition/set/append0` to append a string without an intervening space
* you can use `definition/set/remove` to remove a definition
