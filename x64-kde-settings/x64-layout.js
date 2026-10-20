var panel = new Panel;
var panelScreen = panel.screen;

panel.height = 30;
panel.floating = true;

const maximumAspectRatio = 21/9;
if (panel.formFactor === "horizontal") {
    const geo = screenGeometry(panelScreen);
    const maximumWidth = Math.ceil(geo.height * maximumAspectRatio);

    if (geo.width > maximumWidth) {
        panel.alignment = "center";
        panel.minimumLength = maximumWidth;
        panel.maximumLength = maximumWidth;
    }
}

var kickoff = panel.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "/usr/share/pixmaps/x64-logo.png");

panel.addWidget("org.kde.plasma.pager");

var icontasks = panel.addWidget("org.kde.plasma.icontasks");
icontasks.currentConfigGroup = ["General"];
icontasks.writeConfig("launchers", "applications:systemsettings.desktop,applications:org.kde.dolphin.desktop,applications:org.kde.discover.desktop,applications:com.shellyorg.shelly.desktop,applications:chromium.desktop,applications:kitty.desktop");

panel.addWidget("org.kde.plasma.marginsseparator");
var systemtray = panel.addWidget("org.kde.plasma.systemtray");
systemtray.currentConfigGroup = ["General"];
systemtray.writeConfig("shownItems", "x64-update-tray");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");
