
nclude $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-led
PKG_RELEASE:=1

include $(GLUONDIR)/package/gluon.mk

define Package/$(PKG_NAME)
  TITLE:=Config-Mode UI to select LED color and brightness
  DEPENDS:=+gluon-config-mode-core +gluon-web-model +gluon-led-config
endef

define Package/$(PKG_NAME)/description
 Adds a wizard page to configure LED color (if multi-color) and brightness.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
    $(CP) ./luasrc/* $(1)/usr/lib/lua/
    $(CP) ./i18n/*    $(1)/lib/gluon/config-mode/i18n/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
