#!/bin/bash
#updating for ubuntu 20.04 and python3
# lots of sudo that does not work and needs to be removed
#echo "######## Setup SSH authorized_keys to save Ian time ########"
#mkdir /home/mapr/.ssh/
#cat /public_data/demos_customer360/authorized_keys >> /home/mapr/.ssh/authorized_keys

#Global Variables
USERNAME="ezmeral"
CUSTOMER360_GIT_LINK="https://github.com/lla4um/customer360.git"

echo "######## Installing Customer360 prerequisites ########"
sudo apt-get install apt-transport-https --force-yes -y
sudo apt-get update
#sudo apt-get install rpm2cpio git maven python-virtualenv -y
sudo apt-get install rpm2cpio git maven -y
mkdir .virtualenv
sudo apt install python3-pip -y
sudo pip3 install virtualenvwrapper
#Add to  .bashrc to setup perminatly. Not sure about this yet
##Virtualenvwrapper settings:
#export WORKON_HOME=$HOME/.virtualenvs
#VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
#. /usr/local/bin/virtualenvwrapper.sh
/home/$USERNAME/.bashrc
mkvirtualenv customer360
# mkvirtualenv name_of_your_env
# deactivate
# workon
# workon name_of_your_env
# rmvirtualenv name_of_your_env
#TODO:  need to create a clean=-up and delet all cluster stuff created in script

# tring to convert to NOT use sudo
echo "######## Loading Customer 360 data set ########"
maprcli table delete -path /apps/crm > /dev/null
maprcli table create -path /apps/crm -tabletype json
maprcli table cf edit -path /apps/crm  -cfname default -readperm p -writeperm p
# TODO: Need to remove and add instruction to run from user home
cd /home/$USERNAME
git clone $CUSTOMER360_GIT_LINK
hadoop fs -put /home/$USERNAME/customer360/bokeh/datasets/crm_data.json /tmp
mapr importJSON -idField id -src /tmp/crm_data.json -dst /apps/crm -mapreduce false

# skiping this for now to see if I need to mess with drill
#echo "######## Setup Drill to show queries on all drillbits ########"
#sudo -u mapr scp /public_data/demos_customer360/drill-override.conf mapr@mdn-0.mdn:/opt/mapr/drill/drill-*/conf/drill-override.conf
#sudo -u mapr scp /public_data/demos_customer360/drill-override.conf mapr@mdn-1.mdn:/opt/mapr/drill/drill-*/conf/drill-override.conf
#sudo -u mapr scp /public_data/demos_customer360/drill-override.conf mapr@mdn-2.mdn:/opt/mapr/drill/drill-*/conf/drill-override.conf
#sudo -u mapr ssh mapr@mdn-0.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh stop
#sudo -u mapr ssh mapr@mdn-1.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh stop
#sudo -u mapr ssh mapr@mdn-2.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh stop
#sudo -u mapr ssh mapr@mdn-0.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh start
#sudo -u mapr ssh mapr@mdn-1.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh start
#sudo -u mapr ssh mapr@mdn-2.mdn /opt/mapr/drill/drill-*/bin/drillbit.sh start

echo "######## Enable MapR-DB secondary indexes ########"
# need to adjust this config and read what this command does
maprcli cluster gateway set -dstcluster dsr-demo -gateways mapr-gw
# dont understand why next command is needed
maprcli cluster gateway list

# need to move this to before data fabric work so it can be run with sudo  and not here
echo "######## Install Python stuff ########"
#sudo -u mapr wget https://repo.continuum.io/archive/Anaconda3-4.4.0-Linux-x86_64.sh
#sudo -u mapr bash Anaconda3-4.4.0-Linux-x86_64.sh -b -p /home/mapr/anaconda3
#sudo -u mapr echo "export PATH=/home/mapr/anaconda3/bin/:$PATH" >> /home/mapr/.bashrc
#source /home/mapr/.bashrc
#sudo -u mapr /home/mapr/anaconda3/bin/conda install bokeh=0.12.6 pyodbc pandas -y
###  "# Specific version restrictions  #"
###	bokeh==0.12.6 <----
###	numpy==1.12.1 <----
###	tornado==4.3
###	scipy
###	scikit-learn
###	sklearn
###	pandas==0.18.1 <---
###	plotly==2.0.10
###	pyodbc
pip install bokeh pyodbc pandas numpy tornado==4.3 scipy scikit-learn sklearn plotly==2.0.10

echo "######## Setup ODBC connection to Drill ########"
#sudo apt-get install unixodbc-dev -y
# TODO: move to sudo stuff at top
wget https://package.mapr.hpe.com/tools/MapR-ODBC/MapR_Drill/MapRDrill_odbc_v1.5.1.1002/maprdrill-1.5.1.1002-1.el7.x86_64.rpm
#sudo -u mapr sudo rpm2cpio maprdrill-1.5.1.1002-1.el7.x86_64.rpm | cpio -idmv
rpm2cpio maprdrill-1.5.1.1002-1.el7.x86_64.rpm | cpio -idmv

cp -v /opt/mapr/drill/Setup/odbc.ini ~/.odbc.ini
cp -v /opt/mapr/drill/Setup/odbcinst.ini ~/.odbcinst.ini
cp -v /opt/mapr/drill/Setup/mapr.drillodbc.ini ~/.mapr.drillodbc.ini
# not sure about this next line. root should not be doing any odbc drill calls.
#cp -v /home/mapr/.odbc.ini /home/mapr/.odbcinst.ini /home/mapr/.mapr.drillodbc.ini /root/
# need to move all drill setup to top and use copy of ini from correct location /opt/mapr/drill/Setup/
sudo mv opt/mapr/drill/lib /opt/mapr/drill
sudo mv opt/mapr/drill/Setup /opt/mapr/drill
sudo mv opt/mapr/drill/ErrorMessages /opt/mapr/drill
sudo apt install -y libiodbc2

# TODO check what finaly ends up in .bashrc and adjust
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/opt/mapr/drill/lib/64:/usr/lib64" >> /home/mapr/.bashrc
echo "export ODBCINI=~/.odbc.ini" >> ~/.bashrc
echo "export MAPRDRILLINI=~/.mapr.drillodbc.ini" >> ~/.bashrc

# need to configure drill config files with cluster name and zookeeper info
# Example connection string for direct
#Driver=MapR Drill ODBC Driver;
#ConnectionType=Direct; 
#Host=192.168.222.160;
#Port=31010
# Example Zookeeper conection string
#Driver=MapR Drill ODBC Driver;
#ConnectionType=ZooKeeper;
#ZKQuorum=[*Server1*]:[*PortNumber*1], [*Server2*]:[*PortNumber2*], [*Server3*]:[*PortNumber3*];
#ZKClusterID=[*ClusterName*]
# example query: SELECT * FROM cp.`employee.json` LIMIT 20
# !quit

#???
# pip install pydrill
# path to os odbc installed.. /usr/lib/x86_64-linux-gnu/libiodbc.so.2.1.20
# may updated .mapr.drillodbc.ini with
# Generic ODBCInstLib
#   iODBC
#ODBCInstLib=libiodbcinst.so.2

# don't know if this needs to move to a startDemo script????
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/opt/mapr/drill/lib/64:/usr/lib64 python -c 'import pandas; import pyodbc; print(pyodbc.dataSources()); conn=pyodbc.connect("DSN=drill64",uid="ezmeral",pwd="admin123", autocommit=True); conn.setencoding("utf-8"); cursor = conn.cursor(); print(cursor); print(pandas.read_sql("SELECT * FROM cp.`employee.json` limit 2", conn))'
if [ $? -ne 0 ]; then
        echo "[ERROR] ODBC connection is not working";
        exit 1;
else
        echo "[INFO] Startup script ended successfully.";
#        cd ~/customer360/bokeh/
#        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/usr/lib/x86_64-linux-gnu:/opt/mapr/drill/lib/64:/usr/lib64 python -m bokeh serve . --allow-websocket-origin '*' &
#        disown
fi

exit 0;
