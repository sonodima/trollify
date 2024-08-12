# trollify - stop the crash, troll the app

Modify a decrypted iOS app to prevent it from crashing when sideloaded with
[TrollStore](https://github.com/opa334/TrollStore)

## Usage

1. Clone this repository on your Mac.

```bash
git clone https://github.com/sonodima/trollify && cd trollify
```

2. Install the required dependencies.

```bash
brew install ldid unar
```

3. Copy the app you want to modify to the directory where you cloned this repository.

4. Start the trollification process.

```bash
./trollify.sh <app_name>.ipa <app_name>.tipa
```
