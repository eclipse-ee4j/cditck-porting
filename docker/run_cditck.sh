#!/bin/bash -xe
#
# Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License v. 2.0, which is available at
# http://www.eclipse.org/legal/epl-2.0.
#
# This Source Code may also be made available under the following Secondary
# Licenses when the conditions for such availability set forth in the
# Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
# version 2 with the GNU Classpath Exception, which is available at
# https://www.gnu.org/software/classpath/license.html.
#
# SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0



VER="2.0.0"
if ls ${WORKSPACE}/bundles/*cdi-tck*.zip 1> /dev/null 2>&1; then
  unzip -o ${WORKSPACE}/bundles/*cdi-tck*.zip -d ${WORKSPACE}
else
  echo "[ERROR] TCK bundle not found"
  exit 1
fi

export TS_HOME=${WORKSPACE}/cdi-tck-glassfish-porting

#Install Glassfish
echo "Download and install GlassFish 5.0.1 ..."
wget --progress=bar:force --no-cache $GF_BUNDLE_URL -O latest-glassfish.zip
unzip -o ${WORKSPACE}/latest-glassfish.zip -d ${WORKSPACE}

which ant
ant -version

REPORT=${WORKSPACE}/cdi-tck-report

mkdir -p ${REPORT}/cdi-$VER-sig
mkdir -p ${REPORT}/cdi-$VER

#Edit Glassfish Security policy
cat ${WORKSPACE}/docker/CDI.policy >> ${WORKSPACE}/glassfish5/glassfish/domains/domain1/config/server.policy

#Edit test properties
sed -i "s#porting.home=.*#porting.home=${TS_HOME}#g" ${TS_HOME}/build.properties
sed -i "s#glassfish.home=.*#glassfish.home=${WORKSPACE}/glassfish5/glassfish#g" ${TS_HOME}/build.properties
if [[ "${PROFILE}" == "web" || "${PROFILE}" == "WEB" ]]; then
  sed -i "s#javaee.level=.*#javaee.level=web#g" ${TS_HOME}/build.properties
else
  sed -i "s#javaee.level=.*#javaee.level=full#g" ${TS_HOME}/build.properties
fi
sed -i "s#report.dir=.*#report.dir=${REPORT}#g" ${TS_HOME}/build.properties
sed -i "s#admin.user=.*#admin.user=admin#g" ${TS_HOME}/build.properties

#Run Tests
cd ${TS_HOME}
export MAVEN_OPTS="-Duser.home=$HOME $MAVEN_OPTS"
ant -Duser.home=$HOME sigtest
ant -Duser.home=$HOME test

#Generate Reports
echo "<pre>" > ${REPORT}/cdi-$VER-sig/report.html
cat $REPORT/cdi_sig_test_results.txt >> $REPORT/cdi-$VER-sig/report.html
echo "</pre>" >> $REPORT/cdi-$VER-sig/report.html
cp $REPORT/cdi-$VER-sig/report.html $REPORT/cdi-$VER-sig/index.html

# Copy the test reports to the report directory
cp -R ${TS_HOME}/glassfish-tck-runner/target/surefire-reports/* ${REPORT}/cdi-${VER}
if [[ -f ${REPORT}/cdi-$VER/test-report.html ]];then
  cp ${REPORT}/cdi-$VER/test-report.html ${REPORT}/cdi-${VER}/report.html
fi

mv ${REPORT}/cdi-$VER/TEST-TestSuite.xml  ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
sed -i 's/name=\"TestSuite\"/name="cditck-2.0"/g' ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
# Create Junit formated file for sigtests
echo '<?xml version="1.0" encoding="UTF-8" ?>' > $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testsuite tests="TOTAL" failures="FAILED" name="cdi-2.0.0-sig" time="0" errors="0" skipped="0">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testcase classname="CDISigTest" name="cdiSigTest" time="0.2">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  <system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
cat $REPORT/cdi_sig_test_results.txt >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  </system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testcase>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testsuite>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml

# Fill appropriate test counts
if [ -f "$REPORT/cdi-$VER-sig/report.html" ]; then
  if grep -q STATUS:Passed "$REPORT/cdi-$VER-sig/report.html"; then
    sed -i 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i 's/failures=\"FAILED\"/failures="0"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  else 
    sed -i 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i 's/failures=\"FAILED\"/failures="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  fi
fi

tar zcvf ${WORKSPACE}/cdi-tck-results.tar.gz ${REPORT} ${WORK}
