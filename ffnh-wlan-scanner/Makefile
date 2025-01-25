include $(TOPDIR)/rules.mk

PKG_NAME:=ffnh-wlan-scanner
PKG_VERSION:=1

PKG_MAINTAINER:=Michael Hertel <m.hertel@freifunk-nordhessen.de>

include $(TOPDIR)/../package/gluon.mk

define Package/$(PKG_NAME)
  TITLE:=Simple wireless scanner
  DEPENDS:=+gluon-core
  CATEGORY:=Addon
endef

define Package/$(PKG_NAME)/description
	Allows scanning of wireless envoirement
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
