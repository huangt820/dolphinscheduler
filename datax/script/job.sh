#!/bin/bash

export JAVA_HOME=/opt/java/openjdk
export PATH=$JAVA_HOME/bin:$PATH
export PYTHON_LAUNCHER=/usr/bin/python3
export DATAX_LAUNCHER=/opt/datax/bin/datax.py

JOB_JSON=`dirname $(dirname ${DATAX_LAUNCHER})`/script/job.json

echo $JOB_JSON


JOB_CONTENT=$1

echo "'${JOB_CONTENT}'"

# 变量使用单引号避免转义，因此变量内部需避免使用单引号
PARAMS="\
-Djob_content='${JOB_CONTENT}'\
"

echo $PARAMS

# 执行DataX任务，并通过 -p 参数传递变量（包括使用默认值的变量）
${PYTHON_LAUNCHER} ${DATAX_LAUNCHER} --jvm="-Xms1G -Xmx1G" --loglevel="debug" -p "${PARAMS}" ${JOB_JSON}