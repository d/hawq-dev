#!/bin/bash

set -u -e
set -x

readonly APT_PROXY=http://192.168.177.128:3142

install_packages() {
	sed -i s/enabled=1/enabled=0/ /etc/yum/pluginconf.d/fastestmirror.conf
	local readonly PACKAGES=(
		flex
		bison
		glibc-devel
		pam-devel
		make
		java-1.7.0-openjdk-devel

		# i don't understand why we need the distro's libxml2
		libxml2-devel
		# i don't understand why this isn't part of ext
		libidn-devel

		wget
		rsync
	)

	env http_proxy="${APT_PROXY}" yum install -y "${PACKAGES[@]}"
}

install_ivy() {
	local readonly ANTLIB_PATH=~/.ant/lib
	local readonly IVY_URL=http://supergsego.com/apache/ant/ivy/2.4.0/maven2/2.4.0/ivy-2.4.0.jar

	mkdir -vp "${ANTLIB_PATH}"
	pushd "${ANTLIB_PATH}"
	wget --continue "${IVY_URL}"
	popd
}

_make() {
	pushd /orca

	local readonly EXT_PATH=/orca/ext/rhel5_x86_64

	export JAVA_HOME=/usr/lib/jvm/java
	make sync_tools http_proxy="${APT_PROXY}"
	# sad pandas
	rsync -a "${EXT_PATH}/python-2.6.2" /opt

	local readonly GCC_ENV=(
		"PATH=/opt/gcc-4.4.2/bin:/opt/gcc_infrastructure/bin:/opt/python-2.6.2/bin:$EXT_PATH/gperf-3.0.4-1/bin:$EXT_PATH/apache-maven/bin:$PATH"
		"LD_LIBRARY_PATH=/opt/gcc_infrastructure/lib:/opt/python-2.6.2/lib:$EXT_PATH/lib"
	)
	make devel "${GCC_ENV[@]}" # HOME="$(pwd)"

	popd
}

_main() {
	install_packages

	install_ivy

	_make
}

_main
