# Ubuntu / Iran package mirrors

## Named presets (`--list`)

| ID | Provider |
|----|----------|
| `arvan` | ArvanCloud |
| `iut` | Isfahan University of Technology (`mirror.iut.ac.ir`) |
| `iut-repo` | IUT (`repo.iut.ac.ir`) |
| `iust` | Iran University of Science and Technology |
| `um` | Ferdowsi University of Mashhad |
| `iranserver` | IranServer |
| `sindad` | Sindad Cloud |
| `faraso` | Faraso |
| `pishgaman` | Pishgaman |
| `ir-archive` | `ir.archive.ubuntu.com` |
| `official` | `archive.ubuntu.com` |

## Full catalog

`ubuntu-mirrors.txt` — **128** deduplicated Ubuntu archive URLs (Asia / ME / global).

```bash
./setup-iran-mirrors.sh --list          # named presets
./setup-iran-mirrors.sh --list-all      # full catalog
./setup-iran-mirrors.sh --mirror sindad
./setup-iran-mirrors.sh --url https://mirror.iranserver.com/ubuntu/
./setup-iran-mirrors.sh --auto          # try until apt update works
```

Also used via:

```bash
./scripts/setup-server-shell.sh --yes --iran
./scripts/setup-server-shell.sh --yes --mirror iranserver
./scripts/setup-server-shell.sh --yes --url https://ae.archive.ubuntu.com/ubuntu/
```
