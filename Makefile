include versions.env

INSTANCE  ?= pie
DISK_SPECS := pi-config:1GiB workspace:50GiB
DISKS     := $(foreach s,$(DISK_SPECS),$(firstword $(subst :, ,$(s))))
WORKDIR   := /mnt/lima-workspace
SHELL_IN  := limactl shell $(INSTANCE) --
PI_NPM    := @earendil-works/pi-coding-agent

.DEFAULT_GOAL := help
.PHONY: help disks up down shell pi recreate update status destroy purge-data

help: ## Show targets
	@grep -hE "^[a-z-]+:.*## " Makefile | awk -F':.*## ' '{printf "%-12s %s\n", $$1, $$2}'

disks: ## Create the named volumes (idempotent)
	@# ext4 labels hold 16 chars; Lima labels disks "lima-<name>", so longer names get reformatted on every boot.
	@for d in $(DISKS); do [ $${#d} -le 11 ] || { echo "disk name '$$d' exceeds 11 chars"; exit 1; }; done
	@for s in $(DISK_SPECS); do \
	  d=$${s%%:*}; \
	  limactl disk ls --json 2>/dev/null | grep -q "\"name\":\"$$d\"" || \
	    limactl disk create $$d --size $${s##*:}; \
	done

up: disks ## Create/start the VM, install mise, node and pi
	@limactl ls -q | grep -qx $(INSTANCE) || limactl create --yes --name=$(INSTANCE) lima/pie.yaml
	@limactl ls --format '{{.Status}}' $(INSTANCE) | grep -qx Running || limactl start $(INSTANCE)
	$(SHELL_IN) env MISE_VERSION=$(MISE_VERSION) MISE_SHA256_ARM64=$(MISE_SHA256_ARM64) sh -s < scripts/bootstrap.sh
	$(SHELL_IN) sh -c 'cat > "$$HOME/.config/mise/config.toml"' < vm/mise.toml
	$(SHELL_IN) sh -s < scripts/install-tools.sh

down: ## Stop the VM
	limactl stop $(INSTANCE)

shell: ## Open a shell in the workspace volume
	limactl shell --workdir $(WORKDIR) $(INSTANCE)

pi: ## Run pi in the workspace volume (ARGS="..." passes arguments)
	limactl shell --workdir $(WORKDIR) $(INSTANCE) -- sh -c '. "$$HOME/.config/pie/env" && exec pi "$$@"' sh $(ARGS)

recreate: ## Delete and rebuild the VM; volumes are kept
	-limactl stop $(INSTANCE)
	-limactl delete --force $(INSTANCE)
	$(MAKE) up

update: ## Pin pi to V=x.y.z (must be >= 7 days old); edits vm/mise.toml
	@case "$(V)" in ""|*[!0-9A-Za-z.+-]*) echo "usage: make update V=x.y.z"; exit 1;; esac
	$(SHELL_IN) sh -s -- $(PI_NPM) $(V) 7 < scripts/check-age.sh
	$(SHELL_IN) sh -c '. "$$HOME/.config/pie/env" && mise use -g "npm:$(PI_NPM)@$(V)" && pi --version'
	@# Never copy the guest's config back: a compromised VM could inject mise hooks. Edit the version line only.
	sed -i '' 's|^\("npm:$(PI_NPM)" = \).*|\1"$(V)"|' vm/mise.toml
	@git diff vm/mise.toml

status: ## Show instance, volumes and pi version
	@limactl ls $(INSTANCE)
	@limactl disk ls
	@$(SHELL_IN) sh -c '. "$$HOME/.config/pie/env" && pi --version && mise ls'

destroy: ## Delete the VM only; volumes are kept
	-limactl stop $(INSTANCE)
	limactl delete --force $(INSTANCE)

purge-data: ## DELETE the named volumes (asks first)
	@printf 'Delete volumes $(DISKS) permanently? [y/N] ' && read a && [ "$$a" = y ]
	@for d in $(DISKS); do limactl disk delete $$d; done
