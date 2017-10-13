# This is the project file for the Geometrize desktop app installers.

# Ensure objects and mocs do not go in the destdir build folder
# This avoids the need to filter these out when packaging the installer later
OBJECTS_DIR = object_files # Intermediate object files directory
MOC_DIR = moc_files # Intermediate moc files directory
RCC_DIR = rcc_files # Intermediate rcc files directory
UI_DIR = ui_files # Intermediate ui files directory

# Run the regular Geometrize build
include(geometrize/geometrize.pro)

# Work out the file extension of the built app
isEmpty(TARGET_EXT) {
    win32 {
        TARGET_CUSTOM_EXT = .exe
    }
    macx {
        TARGET_CUSTOM_EXT = .app
    }
} else {
    TARGET_CUSTOM_EXT = $${TARGET_EXT}
}

CONFIG(debug, debug|release) {
    DEPLOY_TARGET_DIR = $$shell_path($${OUT_PWD}/debug)
} else {
    DEPLOY_TARGET_DIR = $$shell_path($${OUT_PWD}/release)
}

# Clean (delete and recreate) the installer package data folder
INSTALLER_PACKAGE_DATA_DIR = $$shell_quote($$shell_path($${_PRO_FILE_PWD_}/installer/packages/com.samtwidale.geometrize/data))
CLEAN_PACKAGE_DATA_DIR = $${QMAKE_DEL_TREE} $${INSTALLER_PACKAGE_DATA_DIR} && $${QMAKE_MKDIR} $${INSTALLER_PACKAGE_DATA_DIR}
QMAKE_POST_LINK = $${CLEAN_PACKAGE_DATA_DIR}

# Copy the Geometrize resources to the installer package data folder
COPY_TO_INSTALLER_PACKAGE = $${QMAKE_COPY_DIR} $$shell_quote($$shell_path($${DEPLOY_TARGET_DIR})) $${INSTALLER_PACKAGE_DATA_DIR}

# Create the Geometrize installer
win32 {

    # Look for local Qt installer framework, else try to download and install it
    IFW_LOCATION = $$(QTDIR)/../../../QtIFW2.0.5/bin/
    exists($${IFW_LOCATION}) {
    } else {
        IFW_LOCATION = $${PWD}/scripts/ifw/bin/
        exists($${IFW_LOCATION}) {
            message("Found a downloaded Qt installer framework, will assume this is AppVeyor CI...")
        } else {
            error("Could not locate the Qt installer framework, is it installed?")
        }
    }

    DEPLOY_COMMAND = windeployqt
    DEPLOY_TARGET = $$shell_quote($$shell_path($${DEPLOY_TARGET_DIR}/$${TARGET}$${TARGET_CUSTOM_EXT}))
    QMAKE_POST_LINK += && $${DEPLOY_COMMAND} $${DEPLOY_TARGET}

    QMAKE_POST_LINK += && $${COPY_TO_INSTALLER_PACKAGE}

    BINARYCREATOR_NAME = binarycreator.exe
    INSTALLER_NAME = geometrize_installer.exe

    BINARYCREATOR_PATH = $$shell_quote($$shell_path($${IFW_LOCATION}$${BINARYCREATOR_NAME}))
    PACKAGES_DIR_PATH = $$shell_quote($$shell_path($${_PRO_FILE_PWD_}/installer/packages))
    INSTALLER_CONFIG_PATH = $$shell_quote($$shell_path($${_PRO_FILE_PWD_}/installer/config/config.xml))
    INSTALLER_GENERATION_COMMAND = $${BINARYCREATOR_PATH} --offline-only --packages $${PACKAGES_DIR_PATH} --config $${INSTALLER_CONFIG_PATH} --verbose $${INSTALLER_NAME}
    QMAKE_POST_LINK += && $${INSTALLER_GENERATION_COMMAND}
}

macx {
    DEPLOY_COMMAND = macdeployqt
    BINARYCREATOR_NAME = binarycreator
    INSTALLERBASE_NAME = installerbase
}

linux {
    DEPLOY_COMMAND = linuxdeployqt
    IFW_LOCATION = $$(QTDIR)/../../../QtIFW2.0.5/bin/ # TODO
    BINARYCREATOR_NAME = binarycreator
    INSTALLERBASE_NAME = installerbase
}

message($$QMAKE_POST_LINK)
