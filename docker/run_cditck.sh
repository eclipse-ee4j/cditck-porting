#!/bin/bash -xe
#
# Copyright (c) 2022, 2022 Contributors to the Eclipse Foundation
# Copyright (c) 2018, 2022 Oracle and/or its affiliates. All rights reserved.
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

VER=4.0.0

if [ -z "$GF_TOPLEVEL_DIR" ]; then
  export GF_TOPLEVEL_DIR=glassfish7
fi


if [[ "$JDK" == "JDK17" || "$JDK" == "jdk17" ]];then
  export JAVA_HOME=${JDK17_HOME}
fi
export PATH=$JAVA_HOME/bin:$PATH

if ls ${WORKSPACE}/bundles/*cdi-tck*.zip 1> /dev/null 2>&1; then
  unzip -o ${WORKSPACE}/bundles/*cdi-tck*.zip -d ${WORKSPACE}
else
  echo "[ERROR] TCK bundle not found"
  exit 1
fi

export TS_HOME=${WORKSPACE}/cdi-tck-glassfish-porting

#Install Glassfish
echo "Download and install GlassFish ..."
wget --progress=bar:force --no-cache $GF_BUNDLE_URL -O ${WORKSPACE}/latest-glassfish.zip
unzip -q -o ${WORKSPACE}/latest-glassfish.zip -d ${WORKSPACE}

if [ -z "${CDI_TCK_VERSION}" ]; then
  CDI_TCK_VERSION=4.0.3
fi

if [ -z "${CDI_TCK_BUNDLE_URL}" ]; then
  CDI_TCK_BUNDLE_URL=https://download.eclipse.org/ee4j/cdi/4.0/cdi-tck-4.0.3-dist.zip
fi

rm -fr glassfish-cdi-porting-tck-master
wget https://github.com/eclipse-ee4j/glassfish-cdi-porting-tck/archive/master.zip -O glassfish-cdi-porting-tck.zip
unzip -q -o glassfish-cdi-porting-tck.zip
cd glassfish-cdi-porting-tck-master
mvn --global-settings "${TS_HOME}/settings.xml" clean install -DskipTests
cd $WORKSPACE


#Install CDI TCK dist
echo "Download and unzip CDI TCK dist ..."
wget --progress=bar:force --no-cache $CDI_TCK_BUNDLE_URL -O latest-cdi-tck-dist.zip
unzip -q -o ${WORKSPACE}/latest-cdi-tck-dist.zip -d ${WORKSPACE}/

GROUP_ID=jakarta.enterprise
CDI_TCK_DIST=cdi-tck-${CDI_TCK_VERSION}

cd ${CDI_TCK_DIST}/artifacts
mvn --global-settings "${TS_HOME}/settings.xml" install

which ant
ant -version

export PATH=$JAVA_HOME/bin:$PATH

which java
java -version

REPORT=${WORKSPACE}/cdi-tck-report

mkdir -p ${REPORT}/cdi-$VER-sig
mkdir -p ${REPORT}/cdi-$VER

#Edit Glassfish Security policy
cat ${WORKSPACE}/docker/CDI.policy >> ${WORKSPACE}/${GF_TOPLEVEL_DIR}/glassfish/domains/domain1/config/server.policy

#Edit test properties
sed -i'' -e "s#porting.home=.*#porting.home=${TS_HOME}#g" ${TS_HOME}/build.properties
sed -i'' -e "s#glassfish.home=.*#glassfish.home=${WORKSPACE}/${GF_TOPLEVEL_DIR}/glassfish#g" ${TS_HOME}/build.properties
if [[ "${PROFILE}" == "web" || "${PROFILE}" == "WEB" ]]; then
  sed -i'' -e "s#javaee.level=.*#javaee.level=web#g" ${TS_HOME}/build.properties
else
  sed -i'' -e "s#javaee.level=.*#javaee.level=full#g" ${TS_HOME}/build.properties
fi
sed -i'' -e "s#report.dir=.*#report.dir=${REPORT}#g" ${TS_HOME}/build.properties
sed -i'' -e "s#admin.user=.*#admin.user=admin#g" ${TS_HOME}/build.properties
sed -i'' -e "s#cdiextjar=.*#cdiextjar=cdi-tck-ext-lib-${CDI_TCK_VERSION}.jar#g" ${TS_HOME}/build.properties
sed -i'' -e "s#cdiext.version=.*#cdiext.version=${CDI_TCK_VERSION}#g" ${TS_HOME}/build.properties

cp ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests.xml ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests_bkup.xml 
cp ${WORKSPACE}/${CDI_TCK_DIST}/artifacts/cdi-tck-core-impl-${CDI_TCK_VERSION}-suite.xml ${TS_HOME}/glassfish-tck-runner/src/test/tck20/tck-tests.xml


#Run Tests
cd ${TS_HOME}
export MAVEN_OPTS="-Duser.home=$HOME $MAVEN_OPTS"
ant $ANT_OPTS sigtest
ant $ANT_OPTS test


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
sed -i'' -e 's/name=\"TestSuite\"/name="cditck-4.0"/g' ${REPORT}/cdi-$VER/cditck-$VER-junit-report.xml
# Create Junit formated file for sigtests
echo '<?xml version="1.0" encoding="UTF-8" ?>' > $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testsuite tests="TOTAL" failures="FAILED" name="cdi-4.0-sig" time="0" errors="0" skipped="0">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '<testcase classname="CDISigTest" name="cdiSigTest" time="0.2">' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  <system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
cat $REPORT/cdi_sig_test_results.txt >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '  </system-out>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testcase>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
echo '</testsuite>' >> $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml

# Fill appropriate test counts
if [ -f "$REPORT/cdi-$VER-sig/report.html" ]; then
  if grep -q STATUS:Passed "$REPORT/cdi-$VER-sig/report.html"; then
    sed -i'' -e 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i'' -e 's/failures=\"FAILED\"/failures="0"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  else 
    sed -i'' -e 's/tests=\"TOTAL\"/tests="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
    sed -i'' -e 's/failures=\"FAILED\"/failures="1"/g' $REPORT/cdi-$VER-sig/cdi-$VER-sig-junit-report.xml
  fi
fi

tar zcvf ${WORKSPACE}/cdi-tck-results.tar.gz ${REPORT} ${WORK} ${WORKSPACE}/${GF_TOPLEVEL_DIR}/glassfish/domains/domain1/logs/
