# my-openbsd-ports

## Configuration

- Fetch the ports tree
- Clone or export the repo
- Add the path for the repo to `PORTSDIR_PATH`: `export PORTSDIR_PATH="/home/ninckblokje/dev/sources/my-openbsd-ports:/usr/ports:/usr/ports/mystuff"`

## Update steps

- `make clean`
- `make makesum`
- `make extract`
- `make build`
- `make clean configure`
- `make fake`
- `make update-plist`

## Build steps

- `make clean`
- `make package`

## Install steps

- `doas make install`

## Uninstall steps

- `doas make uninstall`

## Links

https://www.openbsd.org/faq/ports/guide.html
https://www.openbsd.org/faq/ports/ports.html
https://man.openbsd.org/bsd.port.mk.5
https://man.openbsd.org/go-module.5
