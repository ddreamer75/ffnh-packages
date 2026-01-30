include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-led-maps
PKG_VERSION:=1
PKG_RELEASE:=1

include $(GLUONDIR)/package/gluon.mk

define Package/$(PKG_NAME)
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Drop-in LED Mapping Dateien (Vendor/Board Allow-Lists)
  DEPENDS:=+gluon-config-mode-core
endef

define Package/$(PKG_NAME)/description
 Installiert Drop-in LED-Mappings für den Config-Mode Wizard.
 Alle Dateien unter files/lib/gluon/config-mode/led-map.d/*.lua
 werden ins Root-FS kopiert und vom Wizard zur Laufzeit geladen.
endef

define Build/Compile
  # nichts zu kompilieren
endef

define Package/$(PKG_NAME)/install
    $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
