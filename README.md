#Automation_Project

This project is about writing a script which should update packages on the instance and the check if apache2 is installed or not. If not, then it should auotmatically install it. If yes, then check if apache2 is running or not else enable it.

Next step, is to copy all the log file to s3 bucket.
#Pre-requisites.

- awscli should be installed in your machine. you can install it by running "sudo apt install awscli"
- make user sudo by running "sudo su"

#Steps

- Clone the repo.
- make the automation.sh file executable by running "chmod +x <folder_path>/automation.sh"
- execute automation.sh file using "bash automation.sh"

