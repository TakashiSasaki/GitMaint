ifndef ROOT
  ifdef HOME
    ROOT=$(HOME)
  else
    $(error ROOT and HOME are empty or not set.)
  endif
endif

ifndef USER
  USER=$(shell whoami)
endif

ifndef HOST
  ifdef HOSTNAME
    HOST=$(HOSTNAME)
  else
    ifdef COMPUTERNAME
      HOST=$(COMPUTERNAME)
    else
      ifdef NAME
        HOST=$(NAME)
      else
        HOST=$(shell hostname)
      endif
    endif
  endif
endif


