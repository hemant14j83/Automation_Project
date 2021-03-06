#!/bin/bash
myname="hemant"
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket="upgrad-hemant"
package="apache2"
file_name="$myname-httpd-logs-$timestamp.tar"
html_table_code="<html><head></head><body><table style=margin:auto><tr><th width=30%>Log Type </th><th width=30%> Time Created </th><th width=20%> Type </th><th width=20%> Size</th><tr>"
html_close_table="</table></body></html>"
cronstatus=$(ls /etc/cron.d/ | grep 'automation' && echo 'yes' || echo 'no')

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
tar -cf "$file_name" *.log

mv *.tar /tmp/

#Uploading tar file to s3 bucket
echo "---------------------------------------------------------------"
echo "Copying tar file to s3.."
echo "---------------------------------------------------------------"
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

cd /tmp/

echo "---------------------------------------------------------------"
echo "checking inventory file.."
echo "---------------------------------------------------------------"

if [ -e /var/www/html/inventory.html ]; then
    echo "inventory.html file already exists. Updating content now"
    content="<tr style=text-align:center><td width=25%>$(ls $file_name | cut -d '-' -f 2-3) </td><td width=25%> $timestamp </td><td width=25%> $(ls $file_name | awk -F . '{print $NF}') </td><td width=25%> $(du -k $file_name | cut -f1)</td></tr>"
    sed -i "\$i $content" /var/www/html/inventory.html
else
    echo "inventory.html not found. creating one now.."
    echo $html_table_code > /var/www/html/inventory.html
    echo "<tr style=text-align:center><td width=25%>$(ls $file_name | cut -d '-' -f 2-3) </td><td width=25%> $timestamp </td><td width=25%> $(ls $file_name | awk -F . '{print $NF}') </td><td width=25%> $(du -k $file_name | cut -f1)</td></tr>" >> /var/www/html/inventory.html
    echo $html_close_table >> /var/www/html/inventory.html
fi

#cron job
echo "---------------------------------------------------------------"
echo "checking cronjob .."
echo "---------------------------------------------------------------"
if [[ $cronstatus == "no" ]]; then
    echo "cron job not found, adding one."
    touch /etc/cron.d/automation
    echo "0 8 * * * root /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
else
    echo "automation cron job exists"
fi

echo "---------------------------------------------------------------"
echo "Done ...."
echo "---------------------------------------------------------------"
