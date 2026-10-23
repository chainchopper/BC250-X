# BC-250-X external tree — no custom packages (yet); everything comes from
# upstream Buildroot packages. This file must exist for BR2_EXTERNAL.
include $(sort $(wildcard $(BR2_EXTERNAL_BC250X_PATH)/package/*/*.mk))
