
## <p align="center">Firefox Safari theme</p>

<p align="center">A MacOSX Safari theme for Firefox 80+</p>

![01](https://github.com/vinceliuice/WhiteSur-gtk-theme/blob/pictures/pictures/firefox.svg?raw=true)

This is a bunch of CSS code to make Firefox look closer to MacOSX Safari theme.

Based on https://github.com/rafaelmardojai/firefox-gnome-theme

## Installation

> [!note]
> This project applies custom CSS to Firefox on Linux.
> For other operating systems, refer to the [MacOS and Windows version](#macos-and-windows-version).

Run the following commands in the terminal:

```sh
./install.sh
```

INFO: Do not run it with sudo, or it will install in root user folder !

Usage:  `./install.sh`  **[OPTIONS...]**

```
OPTIONS:

    -m, --monterey [3+3|3+4|3+5|4+3|4+4|4+5|5+3|5+4|5+5] :Topbar buttons (not window control buttons) number: 'a+b'
 .  a: urlbar left side buttons number, b: urlbar right side buttons number


    -a, --alt  
 .  Install 'Monterey' theme alt version for Firefox


    -A, --adaptive  
 .  Install Firefox adaptive color version...


    -e, --edit [(monterey/alt)|adaptive] 
 .  Edit 'WhiteSur' theme for Firefox settings and also connect the theme to the current Firefox profiles


    -r, --remove, --revert  
 .  Remove themes, do the opposite things of install and connect


    -h, --help  
 .  Show this help

```

if you want to edit the style then:

Run `./install.sh -e`

if you want to use `Monterey` style then:

Run `./install.sh -m`

if you want to use `Monterey` `alt` style then:

Run `./install.sh -a`

### MacOS and Windows version
AdamXweb - WhiteSurFirefoxThemeMacOS: https://github.com/AdamXweb/WhiteSurFirefoxThemeMacOS

### Manual installation

1. Go to `about:support` in Firefox.
2. Application Basics > Profile Directory > Open Directory.
3. Copy `chrome` folder Firefox config folder.
4. If you are using Firefox 69+:
	1. Go to `about:config` in Firefox.
	2. Search for `toolkit.legacyUserProfileCustomizations.stylesheets` and set it to `true`.
5. Restart Firefox.
6. Open Firefox customization panel and:
	1. Use *Title bar* option to toggle CSD if is not set by default.
	2. Move the new tab button to headerbar.
	3. Select light or dark variants on theme switcher.
7. Be happy with your new gnomish Firefox.

## Enabling optional features
Open `userChrome.css` with a text editor and follow instructions to enable extra features. Keep in mind this file might change in future versions and your configuration will be lost. You can copy the @imports you want to enable to a new file named `customChrome` directly in your `chrome` directory if you want it to survive updates. Remember all @imports must be at the top of the file, before other statements.

## Known bugs

### CSD have sharp corners
See upstream [bug](https://bugzilla.mozilla.org/show_bug.cgi?id=1408360).

#### Wayland fix:
1. Go to the `about:config` page
2. Search for the `layers.acceleration.force-enabled` preference and set it to true.
3. Now restart Firefox, and it should look good!

#### X11 fix:
1. Go to the `about:config` page
2. Type `mozilla.widget.use-argb-visuals`
3. Set it as a `boolean` and click on the add button
4. Now restart Firefox, and it should look good!

## Development

If you wanna mess around the styles and change something, you might find these
things useful.

To use the Inspector to debug the UI, open the developer tools (F12) on any
page, go to options, check both of those:

- Enable browser chrome and add-on debugging toolboxes
- Enable remote debugging

Now you can close those tools and press Ctrl+Alt+Shift+I to Inspect the browser
UI.
