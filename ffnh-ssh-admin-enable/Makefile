include $(TOPDIR)/rules.mk


PKG_NAME:=ffnh-ssh-admin-enable

include $(TOPDIR)/../package/gluon.mk

define Package/ffnh-ssh-admin-enable
  TITLE:=UI for activate admin-ssh-keys mode flag in the wizard
  DEPENDS:=+gluon-config-mode-core +ffda-ssh-manager
endef

$(eval $(call BuildPackageGluon,ffnh-ssh-admin-enable))
