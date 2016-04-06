TARGET ?= amd64
ARCHS ?= amd64 armhf arm64
BASE_ARCH ?= amd64
DOCKER_REPO ?= openhab/openhab
TRAVIS_GIT_REPO ?= openhab/openhab-docker
TRAVIS_GIT_BRANCH ?= master
FLAVOR ?= online
TRAVIS_TOKEN ?= secretsecret

ifeq ($(FLAVOR),offline)
  DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-offline/target/openhab-offline-2.0.0-SNAPSHOT.zip"
else
  DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-online/target/openhab-online-2.0.0-SNAPSHOT.zip"
endif

build: tmp-$(TARGET)/Dockerfile
	docker build --build-arg ARCH=$(TARGET) --build-arg DOWNLOAD_URL=$(DOWNLOAD_URL) -t $(DOCKER_REPO):$(TARGET)-$(FLAVOR) tmp-$(TARGET)
	docker run --rm $(DOCKER_REPO):$(TARGET)-$(FLAVOR) uname -a

tmp-$(TARGET)/Dockerfile: Dockerfile $(shell find files)
	rm -rf tmp-$(TARGET)
	mkdir tmp-$(TARGET)
	cp Dockerfile $@
	cp -rf files tmp-$(TARGET)/
	for arch in $(ARCHS); do                     \
	  if [ "$$arch" != "$(TARGET)" ]; then       \
	    sed -i "/arch=$$arch/d" $@;              \
	  fi;                                        \
	done
	sed -i '/#[[:space:]]*arch=$(TARGET)/s/^#//' $@
	sed -i 's/#[[:space:]]*arch=$(TARGET)//g' $@
	cat $@

test:
	env IMAGE="$(DOCKER_REPO):$(TARGET)-$(FLAVOR)" \
	bundle exec rspec

clean:
	for arch in $(ARCHS); do                     \
	  rm -rf tmp-$$arch;                      \
	done

push:
	docker push $(DOCKER_REPO):$(TARGET)-$(FLAVOR)

trigger:
	@curl -s -X POST \
	  -H "Content-Type: application/json" \
	  -H "Accept: application/json" \
	  -H "Travis-API-Version: 3" \
	  -H "Authorization: token $(TRAVIS_TOKEN)" \
	  -d '{ "request": { "branch":"$(TRAVIS_GIT_BRANCH)", "token": "$(TRAVIS_TOKEN)" }}' \
	  https://api.travis-ci.org/repo/$(subst /,%2F,$(TRAVIS_GIT_REPO))/requests
