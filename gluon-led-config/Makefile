include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-led-config
PKG_RELEASE:=1

include $(GLUONDIR)/package/gluon.mk

define Package/$(PKG_NAME)
  TITLE:=Apply configurable LED color/brightness at boot
  DEPENDS:=+gluon-core
endef

define Package/$(PKG_NAME)/description
 Configures LED triggers and brightness persistently via sysfs.
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
    $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
``
