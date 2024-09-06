# save-emu

A bash script to synchronize and backup emulator savegames online or offline on multiple devices. The main purpose of this script is to transfer the savegames of an emulator from one computer to another with only one command on each computer. I developed this script to enable seamless continuation of an emulator savegame on either my laptop or desktop PC. It should be possible to execute a single command to initiate this process and to maintain a record of the savegame states, such as the device and time of the last emulator session.

## Functionality

This script creates a .info and .synchronization file in the directory whose path is stored in the LOCAL_SAVEGAME_DIRECTORY variable. The .info file contains the local status of the (emulator) savegames (such as Date, Platform, Filename and Size), while the .synchronization file contains the online status of the (emulator) savegames. The script creates, updates and needs this information to identify outdated or up-to-date savegames. The most important one is the date, which marks the exact date of creation of the specific compressed savegame file. The platform lets the user recognize from which computer the savegame was created, e.g. “Desktop”, “Laptop” or “Toaster”. The above mentioned directory also contains the compressed savegame files and possible backups of the compressed savegame files. The export option automatically creates the compressed savegame files, updates the .info and .synchronization file and uploads the specific savegames and .synchronization file to your own specific webspace directory (if possible/activated). This is achieved by using scp with a public key on your webspace and a private key on your machines that you'll need to create beforehand.

## Export - Create a compressed savegame file (and upload it)

The export option creates a compressed savegame file in the directory whose path is stored in the LOCAL_SAVEGAME_DIRECTORY variable. Then, the export option updates the .info and .synchronization file and uploads both the compressed savegame file and the .synchronization file to your webspace, if possible/activated.

- Example: `./save-emu.sh export -a`

## Import - (Download a compressed savegame file and) restore it

The import option decompresses a compressed savegame file in the right emulator directory and updates the .info file accordingly. If possible/activated, the import option downloads the compressed savegame file beforehand.

- Example: `./save-emu.sh import -a`

## Change user variables

The user variables can be changed with the -/ and -! options.

- First, have a look on the user variables by typing: `./save-emu.sh -/`
- Change the respective variable by using -! and the variable number. For example: `./save-emu.sh -! 7 Laptop`
- If you want to use blankspaces, make sure to use quotation marks around the whole text! For Example: `./save-emu.sh -! 7 "My Laptop"`
- 7 is the user variable number for **PLATFORM**, which indicates the specific computer.

Of course the user variables can also be changed directly in the code. You will find these quite on the top of the script.

## Available import/export options

- `-a|--all` save all savegames
- `-2|-ps2|--pcsx2` save all PCSX2 savegames
- `-p|-psp|--ppsspp` save all PPSSPP savegames
- `-d|-wii|-gc|--dolphin` save all Dolphin savegames
- `-c|-3ds|--citra` save all Citra savegames
- `-n|--no` no online/cloud backup (Not necessary if the cloud feature is deactivated)

## Available options

- `-s|--status` show status
- `-/|--path|--var` show (path) variables
- `-!|--change_var` change a (path) variable
- `-v|--version` show version
- `-h|--help` show help page

## Usage examples

- `./save-emu.sh export -p`
- `./save-emu.sh export -n -p`
- `./save-emu.sh import -p`
- `./save-emu.sh -h`
- `./save-emu.sh -s`
- `./save-emu.sh -n -s`

## Create SSH key to use the online feature on your own webspace

`key` is the name of the key in the following, which should be changed to a fitting key name:

0. Go to your .ssh directory. For example: `cd ~/.ssh/`
1. Generate key: `ssh-keygen -t ed25519 -f key`
2. Copy the public key to your webspace. For example with scp: `scp key.pub user@remote_ip_address:/.ssh/`
3. Connect to the server with SSH: `ssh user@remote_ip_address`
4. `chmod 700 .ssh`
5. `cd .ssh`
6. `cat key.pub >> /.ssh/authorized_keys`
7. `chmod 0600 authorized_keys`
8. `rm key.pub`
9. `exit`

It should then be possible to copy data with scp -i, which is used by the script. For example: scp -i ~/.ssh/key test.txt user@remote_ip_address:/backup/

