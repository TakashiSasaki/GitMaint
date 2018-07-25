define resetColor
	@bash -c 'echo -e "\e[m"'
endef

define black
	@bash -c 'echo -e "\e[30m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define red
	@bash -c 'echo -e "\e[31m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define green
	@bash -c 'echo -e "\e[32m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define yellow
	@bash -c 'echo -e "\e[33m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define blue
	@bash -c 'echo -e "\e[34m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define magenta
	@bash -c 'echo -e "\e[35m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define cyan
	@bash -c 'echo -e "\e[36m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define white
	@bash -c 'echo -e "\e[37m"$1$2$3$4$5$6$7$8$9"\e[m"'
endef

define enter
$(if $(filter %.out,$@),$(call cyan,"=> $@"))
$(if $(filter %.files,$@),$(call green,"=> $@"))
$(if $(filter %.dirs,$@),$(call yellow,"=> $@"))
$(if $(suffix $@),,$(call magenta,"=> $@"))
endef

define leave
@#$(if $(filter %.out,$@),$(call cyan,"<= $@"))
@#$(if $(filter %.files,$@),$(call green,"<= $@"))
@#$(if $(filter %.dirs,$@),$(call yellow,"<= $@"))
@#$(if $(suffix $@),,$(call magenta,"<= $@"))
endef

testColors:
	$(call enter)
	$(call red,red)
	$(call blue,blue)
	$(call green,green)
	$(call white,white)
	$(call magenta,magenta)
	$(call cyan,cyan)
	$(call yellow,yellow)
	$(call leave)

