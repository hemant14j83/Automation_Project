#!/bin/bash
myname="hemant"
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket="upgrad-hemant"
package="apache2"

echo "---------------------------------------------------------------"
echo "running update.."
echo "---------------------------------------------------------------"
apt update -y

echo "---------------------------------------------------------------"
echo "verifying apache2 installation..."
echo "---------------------------------------------------------------"

for pkg in $package; do
    if dpkg --get-selections | grep -q "^$pkg[[:space:]]*install$" >/dev/null; then
        echo "---------------------------------------------------------------"
        echo "$pkg is installed! skipping installation"
        echo "---------------------------------------------------------------"
    else
        echo "---------------------------------------------------------------"
        echo "$pkg is NOT installed! installing apache2"
        echo "---------------------------------------------------------------"
        sudo apt install apache2 -y
    fi
done

status=$(systemctl status apache2 | awk '/running/ {print $2}')
expectedStatus="active"

if [[ $status == $expectedStatus ]]; then
    echo "---------------------------------------------------------------"
    echo "apache2 is Running"
    echo "---------------------------------------------------------------"
else
    echo "---------------------------------------------------------------"
    echo "apache status is stopped, starting apache server.."
    echo "---------------------------------------------------------------"
    systemctl start apache2
fi

bootstatus=$(systemctl status apache2 | awk '/Loaded/ {print}' | cut -d ";" -f 2 | xargs)

if [[ $bootstatus == "disabled" ]]; then
    echo "---------------------------------------------------------------"
    echo "apache is disabled, enabling apache server.."
    echo "---------------------------------------------------------------"
    systemctl enable apache2
else
    echo "---------------------------------------------------------------"
    echo "apache is enabled"
    echo "---------------------------------------------------------------"
fi

#creating tar file and moving to /tmp folder
cd /var/log/apache2
tar -cf "$myname-httpd-logs-$timestamp.tar" *.log
mv *.tar /tmp/.

echo "---------------------------------------------------------------"
echo "Copying tar file to s3.."
echo "---------------------------------------------------------------"
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar


