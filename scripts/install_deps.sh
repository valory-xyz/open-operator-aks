#!/bin/bash
### usage
# mac/linux: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/valory-xyz/open-aea/main/scripts/install.sh)"

TERRAFORM_VERSION=1.3.4

function bad_os_type() {
	echo "OS $OSTYPE is not supported!"
	exit 1
}

function check_linux() {
	# check any deb distribution!
	is_ubuntu=`cat /etc/issue|grep -i Ubuntu`
	if  [[ -z $is_ubuntu ]];
	then
		echo  "Only Ubuntu, MacOS are supported at the moment with this script. please use install.ps1 for Windows 10."
		exit 1
	fi
	install_on_ubuntu
}


function is_python3(){
	return `which python3`
}

function is_python_version_ok() {
	if which python3 2>&1 >/dev/null;
	then
		version=`python3 -V 2>/dev/null`
		if [[ -z `echo $version|grep -E 'Python 3\.(7|8|9|10)\.[0-9]+'` ]];
		then
			echo "Python3 version: ${version} is not supported. Supported versions are 3.7, 3.8, 3.9, 3.10."
			return 1
		fi
		return 0
	else
		echo "Python is not installed"
		return 1
	fi
}


function install_ubuntu_deps(){
	# Always install them because python3-dev can be missing! Also it's not consuming much time.
	echo "Install python3 and dependencies"
	output=$(sudo bash -c "apt update &&  apt install python3 python3-pip python3-dev unzip -y" 2>&1)
	if [[  $? -ne 0 ]];
	then
		echo "$output"
		echo -n '\n\nFailed to install required packages!'
		exit 1
	fi

}

function check_python_version(){
	output=$(is_python_version_ok)
	if [[ $? -eq 1 ]];
	then
		echo "$output"
		echo "Can not install supported python version. probably distribution is too old. Exit."
		exit 1
	fi
}

function ensure_brew(){
	output=`which brew`
	if [[ $? -ne 0 ]];
	then
		echo "Installing homebrew. Please pay attention, it can ask for the password and aggree to install xcode tools."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
		if [[ $? -eq 0 ]];
		then
			echo "Homebrew was installed!"
		else
			echo "Homebrew failed to install!"
		fi
	fi
}

function mac_install_python(){
	output=`is_python_version_ok`
	if [[ $? -eq 0 ]];
	then
		echo "Python supported version already installed!"
		return 0
	fi

	ensure_brew
	echo "Install python3.8. It takes long time."
	output=$(brew install python@3.8 2>&1)
	if [[ $? -eq 0 ]];
	then
		echo "Python was successfully installed!"
		return 0
	else
		echo "$output"
		echo "Python failed to install!"
		exit 1
	fi
}



function install_on_mac(){
	mac_install_python
	check_python_version
}
function install_on_ubuntu(){
	install_ubuntu_deps
	check_python_version
    install_terraform_linux
}


function install_terraform_linux(){
    curl -o terraform.zip https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_$(echo $TERRAFORM_VERSION)_linux_amd64.zip && \
        unzip terraform.zip -d terraform && \
        sudo install terraform/terraform /usr/bin && \
        rm -r terraform terraform.zip && \
        echo "Installed terraform"
    if terraform version; then
        echo "Successfully setup terraform"
    else
        echo "Unable to setup Terraform."
        exit 1
    fi
}


function main(){
	echo "Welcome to Open Autonomy Operator installer!"
	case "$OSTYPE" in
	  darwin*)  install_on_mac ;;
	  linux*)   check_linux ;;
	  *)        bad_os_type ;;
	esac
}

main
