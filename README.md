# snapper-enhanced

Enhancement that will add last apt command as the description of the pre/post snapshot.

![snapper-enhanced Image](https://tmiland.github.io/snapper-enhanced/res/snapper-enhanced.png)

```bash
                                                          __                              __
    _________  ____ _____  ____  ___  _____   ___  ____  / /_  ____ _____  ________  ____/ /
   / ___/ __ \/ __ `/ __ \/ __ \/ _ \/ ___/  / _ \/ __ \/ __ \/ __ `/ __ \/ ___/ _ \/ __  / 
  (__  ) / / / /_/ / /_/ / /_/ /  __/ /     /  __/ / / / / / / /_/ / / / / /__/  __/ /_/ /  
 /____/_/ /_/\__,_/ .___/ .___/\___/_/      \___/_/ /_/_/ /_/\__,_/_/ /_/\___/\___/\__,_/   
                 /_/   /_/                                                                     

Options are:

--install                      | -i
--uninstall                    | -u
--reinstall                    | -r
--install-snapper              | -s
--install-snapper-rollback     | -isr
--install-grub-btrfs           | -igb
--install-btrfs-assistant      | -iba
```
## Installation
- Latest release
```bash
git clone https://github.com/tmiland/snapper-enhanced.git ~/.snapper-enhanced \
cd ~/.snapper-enhanced \
git fetch --tags \
latestTag=$(git describe --tags "$(git rev-list --tags --max-count=1)") \
git checkout $latestTag \
./install -i
```

- Master
```bash
git clone https://github.com/tmiland/snapper-enhanced.git ~/.snapper-enhanced \
cd ~/.snapper-enhanced \
./install -i
```

To reinstall
```bash
./install -r
```

To uninstall
```bash
./install -u
```

## Inspiration
- [openSUSE/snapper](https://github.com/openSUSE/snapper) on Debian.
- [Debian snapper apt script](https://gist.github.com/imthenachoman/f722f6d08dfb404fed2a3b2d83263118) to get last apt command.
- [Antynea/grub-btrfs](https://github.com/Antynea/grub-btrfs) to update grub.
- [wmutschl/timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) for configuration.

## Donations
<a href="https://coindrop.to/tmiland" target="_blank"><img src="https://coindrop.to/embed-button.png" style="border-radius: 10px; height: 57px !important;width: 229px !important;" alt="Coindrop.to me"></img></a>

### Disclaimer 

*** ***Use at own risk*** ***

### License

[![MIT License Image](https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/MIT_logo.svg/220px-MIT_logo.svg.png)](https://tmiland.github.io/snapper-enhanced/LICENSE)

[MIT License](https://tmiland.github.io/snapper-enhanced/LICENSE)