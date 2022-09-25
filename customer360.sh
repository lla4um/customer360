#!/bin/bash

COMMAND=$1
PORT=$2
PID=''
if  [ "$COMMAND" == "start" ]; then
    echo "[INFO] starting customer360 demo"
    if [ "x$PORT" == "x" ]; then
        echo "[INFO] bokeh port set to 5006"
        PORT=5006
    else
        echo "[INFO] bokeh port set to $PORT"
    fi
    echo "[INFO] testing odbc connectivity"
    python -c 'import pandas; import pyodbc; print(pyodbc.dataSources()); conn=pyodbc.connect("DSN=drill64",uid="ezmeral",pwd="admin123", autocommit=True); conn.setencoding("utf-8"); cursor = conn.cursor(); print(cursor); print(pandas.read_sql("SELECT * FROM cp.`employee.json` limit 2", conn))'
    if [ $? -ne 0 ]; then
        echo "[ERROR] ODBC connection testing failed";
        exit 1;
    else
        echo "[INFO] ODBC connection test completed successfully.";
        echo "[INFO] starting bokeh server on port $PORT in the background"
        cd ~/customer360/bokeh/
        python -m bokeh serve . --allow-websocket-origin '*' --port $PORT &
        disown
    fi
elif [ "$COMMAND" == "stop" ]; then
    echo "[INFO] stoping customer360 demo"
    echo "[INFO] looking for running bokeh process ID"
    PID=`pgrep -f bokeh`
    echo "[INFO] bokeh service PID set to $PID"
    echo "[INFO] killing $PID"
    kill $PID
else
    echo "unrecognized command. command should be start or stop. command found was -> $1 <-"
    echo "usage:"
    echo "    customer360.sh start"
    echo "        used to start the bokeh server on port 5006 and stat the demo"
    echo "    customer360.sh stop"
    echo "        used to kill the running bokeh servcie and end the demo"
fi
echo "[INFO] end of customer360.sh script"

